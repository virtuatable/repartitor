describe Controllers::Websockets do
  before do
    DatabaseCleaner.clean
    allow_any_instance_of(Services::Repartitor).to receive(:send_to_websocket).and_return(true)
  end

  let!(:account) { create(:account) }
  let!(:application) { create(:application, creator: account) }
  let!(:gateway) { create(:gateway) }
  let!(:service) { Services::Repartitor.instance }
  let!(:campaign) { create(:campaign, creator: account) }
  let!(:service) { create(:ws_service) }
  let!(:instance) { create(:instance, service: service) }

  def app
    Controllers::Websockets.new
  end

  describe 'GET /url' do
    describe 'Nominal case' do
      before do
        get '/url', {token: 'test_token', app_key: 'other_key'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({url: 'wss://websockets.com/websockets'})
      end
    end
  end

  describe 'POST /messages' do
    describe 'Nominal case' do
      describe 'with an account' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', account_id: account.id.to_s, message: 'test'}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({message: 'transmitted'})
        end
      end
      describe 'with a campaign' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', campaign_id: campaign.id.to_s, message: 'test'}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({message: 'transmitted'})
        end
      end
      describe 'with an array of accounts' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', account_ids: [account.id.to_s], message: 'test'}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({message: 'transmitted'})
        end
      end
    end

    describe '400 errors' do
      describe 'when the message is not given' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', account_id: account.id.to_s}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'message',
            error: 'required'
          })
        end
      end
      describe 'when the message is given empty' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', account_id: account.id.to_s, message: ''}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'message',
            error: 'required'
          })
        end
      end
      describe 'when none of the IDs are given' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', message: 'test'}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'any_id',
            error: 'required'
          })
        end
      end
    end

    describe '404 errors' do
      describe 'account not found' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', message: 'test_message', account_id: 'test_id'}
        end
        it 'Returns a Not Found (404) status' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 404,
            field: 'account_id',
            error: 'unknown'
          })
        end
      end
      describe 'either account not found' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', message: 'test_message', account_ids: ['test_id', 'other_id']}
        end
        it 'Returns a Not Found (404) status' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 404,
            field: 'account_id',
            error: 'unknown'
          })
        end
      end
      describe 'campaign not found' do
        before do
          post '/messages', {token: 'test_token', app_key: 'other_key', message: 'test_message', campaign_id: 'test_id'}
        end
        it 'Returns a Not Found (404) status' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 404,
            field: 'campaign_id',
            error: 'unknown'
          })
        end
      end
    end
    
    it_behaves_like 'a route', 'post', '/messages'
  end
end