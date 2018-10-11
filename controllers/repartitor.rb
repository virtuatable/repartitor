require 'sinatra/custom_logger'

module Controllers
  # Controller handling the websockets, creating it and receiving the commands for it.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Repartitor < Arkaan::Utils::Controller

    load_errors_from __FILE__

    declare_route 'get', '/url' do
      add_body_to_params
      service = Arkaan::Monitoring::Service.where(key: 'websockets').first
      instance = service.instances.where(active: true, running: true).sample
      base_url = instance.url.gsub(/^http/, 'ws').gsub(/\/$/, '')
      halt 200, {url: "#{base_url}/websockets"}.to_json
    end

    declare_route 'post', '/messages' do
      add_body_to_params
      # The message have to be sent, even if the additional data are optional.
      check_presence 'message', route: 'messages'
      # A message can be sent to either : one user, several users, and all the users of a single campaign.
      check_either_presence 'account_id', 'campaign_id', 'account_ids', 'username', route: 'messages', key: 'any_id'

      session = check_session('messages')

      begin
        Services::Repartitor.instance.forward_message(session, params)
        halt 200, {message: 'transmitted'}.to_json
      rescue Services::Exceptions::ItemNotFound => exception
        custom_error 404, exception.to_s
      end
    end
  end
end