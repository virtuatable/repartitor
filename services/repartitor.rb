module Services
  # This singleton service manages the different instances of websockets associated to the different users.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Repartitor
    include Singleton

    # Forwards the message by finding if it's for a campaign, a user, or several users.
    # @param params [Hash] an object containing all the needed properties for the message to be forwarded.
    def forward_message(params)
      if !params['account_id'].nil?
        send_to_account(params['account_id'], params['message'], params['data'] || {})
      elsif !params['account_ids'].nil?
        send_to_accounts(params['account_ids'], params['message'], params['data'] || {})
      elsif !params['campaign_id'].nil?
        send_to_campaign(params['campaign_id'], params['message'], params['data'] || {})
      end
    end

    def send_to_sessions(sessions, message, data)
      service = Arkaan::Monitoring::Service.where(key: 'websockets').first
      if !service.nil?
        grouped = sessions.group_by { |session| session.websocket_id }
        grouped.each do |websocket_id, sessions|
          websocket = service.instances.where(_id: websocket_id).first
          if !websocket.nil?
            send_to_websocket(websocket.url, sessions.pluck(:_id).map(&:to_s), message, data)
          end
        end
      end
    end

    def send_to_websocket(ws_url, session_ids, message, data)
      process = fork {
        Faraday.new(:url => ws_url).post do |req|
          req.url '/messages'
          req.headers['Content-Type'] = 'application/json'
          req.body = {message: message, data: data, session_ids: session_ids}.to_json
        end
      }
      Process.detach(process)
    end

    # Sends a message to all the connected sessions of a user so that he sees it on all its terminals.
    # @param account_id [String] the uniq identifier of the account you're trying to reach.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_account(account_id, message, data)
      account = Arkaan::Account.where(_id: account_id).first
      raise Services::Exceptions::ItemNotFound.new('account_id') if account.nil?
      send_to_sessions(account.sessions, message, data)
    end

    # Sends a message to all the users of a campaign (all accepted or creator invitations in the campaign)
    # @param campaign_id [String] the uniq identifier of the campaign.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_campaign(campaign_id, message, data)
      campaign = Arkaan::Campaign.where(_id: campaign_id).first
      raise Services::Exceptions::ItemNotFound.new('campaign_id') if campaign.nil?
      invitations = campaign.invitations.where(:enum_status.in => ['creator', 'accepted'])
      sessions = Arkaan::Authentication::Session.where(:account_id.in => campaign.invitations.pluck(:account_id))
      send_to_sessions(sessions, message, data)
    end

    # Sends a message to all users in a list of accounts.
    # @param account_ids [Array<String>] the uniq identifiers of the accounts you're trying to reach.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_accounts(account_ids, message, data)
      account_ids.each do |account_id|
        account = Arkaan::Account.where(_id: account_id).first
        raise Services::Exceptions::ItemNotFound.new('account_id') if account.nil?
      end
      sessions = Arkaan::Authentication::Session.where(:account_id.in => account_ids)
      send_to_sessions(sessions, message, data)
    end
  end
end