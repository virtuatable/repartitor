FactoryGirl.define do
  factory :empty_service, class: Arkaan::Monitoring::Service do

    factory :ws_service do
      key 'websockets'
      path '/websockets'
      diagnostic '/status'
    end
  end
end