FactoryGirl.define do
  factory :empty_session, class: Arkaan::Authentication::Session do
    factory :session do
      token 'session_token'
    end
    factory :random_session do
      token { Faker::Number.number(50) }
    end
  end
end