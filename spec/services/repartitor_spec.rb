RSpec.describe Services::Repartitor do

  before do
    DatabaseCleaner.clean
  end

  let!(:account) { create(:account) }
  let!(:other_account) { create(:account, email: 'other@account.com', username: 'other account') }
  let!(:application) { create(:application, creator: account) }
  let!(:gateway) { create(:gateway) }
  let!(:service) { create(:ws_service) }
  let!(:instance) { create(:instance, service: service) }
  let!(:session) { create(:session, account: account, websocket_id: instance.id.to_s) }
  let!(:other_session) { create(:session, account: other_account, websocket_id: instance.id.to_s) }
  let!(:campaign) { create(:campaign, creator: account) }
  let!(:invitation) { create(:invitation, account: other_account, campaign: campaign, enum_status: :accepted)}
  let!(:decorator) { Arkaan::Decorators::Gateway.new('messages', gateway) }

  before :each do
    allow(decorator).to receive(:post).and_return(true)
    allow(Arkaan::Factories::Gateways).to receive(:random).with('messages').and_return(decorator)
  end

  describe :forward_message do
    describe 'with an account' do
      it 'Receives the correct call to the specific forward method' do
        expect(decorator).to receive(:post).with(
          session: session,
          url: '/websockets/messages',
          params: {
            session_ids: [session.id.to_s],
            instance_id: instance.id.to_s,
            message: 'test',
            data: {'key' => 1}
          }
        )
        Services::Repartitor.instance.forward_message(session, {
          'session_id' => session.id.to_s,
          'account_id' => account.id.to_s,
          'message' => 'test',
          'data' => {'key' => 1}
        })
      end
    end
    describe 'with several accounts' do
      it 'Receives the correct call to the specific forward method' do
        expect(decorator).to receive(:post).with(
          session: session,
          url: '/websockets/messages',
          params: {
            session_ids: [session.id.to_s],
            instance_id: instance.id.to_s,
            message: 'test',
            data: {'key' => 1}
          }
        )
        Services::Repartitor.instance.forward_message(session, {
          'session_id' => session.id.to_s,
          'account_ids' => [account.id.to_s],
          'message' => 'test',
          'data' => {'key' => 1}
        })
      end
    end
    describe 'with a campaign' do
      let!(:campaign) { create(:campaign, creator: account) }
      it 'Receives the correct call to the specific forward method' do
        expect(decorator).to receive(:post).with(
          session: session,
          url: '/websockets/messages',
          params: {
            session_ids: [other_session.id.to_s],
            instance_id: instance.id.to_s,
            message: 'test',
            data: {'key' => 1}
          }
        )
        Services::Repartitor.instance.forward_message(session, {
          'session_id' => session.id.to_s,
          'campaign_id' => campaign.id.to_s,
          'message' => 'test',
          'data' => {'key' => 1}
        })
      end
    end
  end

  describe :send_to_account do
    it 'makes the correct call to the send_to_sessions method' do
      expect(Services::Repartitor.instance).to receive(:send_to_sessions).with(
        session, [session], 'test', {'key' => 1}
      )
      Services::Repartitor.instance.send_to_account(session, account.id.to_s, 'test', {'key' => 1})
    end
  end

  describe :send_to_accounts do
    it 'makes the correct call to the send_to_sessions method' do
      expect(Services::Repartitor.instance).to receive(:send_to_sessions).with(
        session, [session], 'test', {'key' => 1}
      )
      Services::Repartitor.instance.send_to_accounts(session, [account.id.to_s], 'test', {'key' => 1})
    end
  end

  describe :send_to_campaign do
    it 'makes the correct call to the send_to_sessions method' do
      expect(Services::Repartitor.instance).to receive(:send_to_sessions).with(
        session, [other_session], 'test', {'key' => 1}
      )
      Services::Repartitor.instance.send_to_campaign(session, campaign.id.to_s, 'test', {'key' => 1})
    end
  end

  describe :send_to_sessions do
    it 'makes the correct call to send_to_websockets' do
      expect(Services::Repartitor.instance).to receive(:send_to_websocket).with(
        session, instance.id.to_s, [session.id.to_s], 'test', {'key' => 1}
      )
      Services::Repartitor.instance.send_to_sessions(session, [session], 'test', {'key' => 1})
    end
  end
end