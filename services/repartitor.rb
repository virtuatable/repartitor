# frozen_string_literal: true

module Services
  # This singleton service manages the different instances of websockets associated to the different users.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Repartitor
    include Singleton

    attr_accessor :logger

    def initialize
      @logger = Services::Logging.instance
    end

    # Forwards the message by finding if it's for a campaign, a user, or several users.
    # @param params [Hash] an object containing all the needed properties for the message to be forwarded.
    def forward_message(session, params)
      try_send_to_account(session, params) ||
        try_send_to_accounts(session, params) ||
        try_send_to_campaign(session, params) ||
        try_send_to_username(session, params)
    end

    %w[account_id account_ids campaign_id username].each do |field|
      method_name = "send_to_#{field.gsub(/_id/, '')}"
      define_method "try_#{method_name}".to_sym do |session, params|
        return false if params[field].nil?

        message = params['message']
        data = params['data'] || {}
        send(method_name.to_sym, session, params[field], message, data)
      end
    end

    # Forwards a request to all the sessions needing it.
    # @param session [Arkaan::Authentication::Session] the session of the account making the notification to the other accounts.
    # @param sessions [Array<Arkaan::Authentication::Session>] the sessions you want to notify.
    # @param message [String] the action of the message.
    # @param data [Hash] a hash of additional data to send with the message.
    def send_to_sessions(session, sessions, message, data)
      service = Arkaan::Monitoring::Service.where(key: 'websockets').first
      return if service.nil?

      logger.sessions(sessions)
      grouped = sessions.group_by(&:websocket_id)
      grouped.each do |websocket_id, tmp_sessions|
        logger.sent_to(websocket_id, tmp_sessions)
        session_ids = tmp_sessions.pluck(:_id).map(&:to_s)
        send_to_websocket(session, websocket_id, session_ids, message, data)
      end
    end

    # Sends the message to the given instance of the websockets service, and to the given sessions.
    # @param session [Arkaan::Authentication::Session] the session of the account making the notification to the other accounts.
    # @param instance_id [ObjectId] the unique identifier of the instance to reach.
    # @param sessions [Array<Arkaan::Authentication::Session>] the sessions you want to notify.
    # @param message [String] the action of the message.
    # @param data [Hash] a hash of additional data to send with the message.
    def send_to_websocket(session, instance_id, session_ids, message, data)
      parameters = {
        session: session,
        url: '/websockets/messages',
        params: params(session_ids, instance_id, message, data)
      }
      logger.info(parameters.to_json)
      Arkaan::Factories::Gateways.random('messages').post(parameters)
    end

    def params(session_ids, instance_id, message, data)
      {
        session_ids: session_ids,
        instance_id: instance_id,
        message: message,
        data: data
      }
    end

    # Sends a message to all the connected sessions of a user so that he sees it on all its terminals.
    # @param account_id [String] the uniq identifier of the account you're trying to reach.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_account(session, account_id, message, data)
      account = Arkaan::Account.where(_id: account_id).first
      raise Services::Exceptions::ItemNotFound, 'account_id' if account.nil?

      send_to_sessions(session, account.sessions, message, data)
    end

    # Sends a message to all the users of a campaign (all accepted or creator invitations in the campaign)
    # @param campaign_id [String] the uniq identifier of the campaign.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_campaign(session, campaign_id, message, data)
      campaign = Arkaan::Campaign.where(_id: campaign_id).first
      raise Services::Exceptions::ItemNotFound, 'campaign_id' if campaign.nil?

      logger.sent_to_campaign(campaign)
      account_ids = filter_invitations(campaign).pluck(:account_id)
      sessions = Arkaan::Authentication::Session.where(
        :account_id.in => account_ids,
        :id.ne => session.id
      )
      send_to_sessions(session, sessions, message, data)
    end

    # Sends a message to all users in a list of accounts.
    # @param account_ids [Array<String>] the uniq identifiers of the accounts you're trying to reach.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_accounts(session, account_ids, message, data)
      if nil_account?(account_ids)
        raise Services::Exceptions::ItemNotFound, 'account_id'
      end

      sessions = Arkaan::Authentication::Session.where(
        :account_id.in => account_ids
      )
      send_to_sessions(session, sessions, message, data)
    end

    def send_to_username(session, username, message, data)
      account = Arkaan::Account.where(username: username).first
      raise Services::Exceptions::ItemNotFound, 'username' if account.nil?

      send_to_sessions(session, account.sessions, message, data)
    end

    def nil_account?(account_ids)
      account_ids.any? do |account_id|
        Arkaan::Account.where(_id: account_id).first.nil?
      end
    end

    def filter_invitations(campaign)
      campaign.invitations.where(
        :enum_status.in => %w[creator accepted]
      )
    end
  end
end
