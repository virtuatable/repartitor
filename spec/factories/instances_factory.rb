FactoryGirl.define do
  factory :empty_instance, class: Arkaan::Monitoring::Instance do
    factory :instance do
      url 'https://websockets.com/'
      active true
      running true
      type :local
    end
  end
end