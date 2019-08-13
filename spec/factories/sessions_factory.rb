FactoryGirl.define do
  factory :empty_session, class: Arkaan::Authentication::Session do
    factory :session do
      token { Faker::Number.number(digits: 50) }
    end
  end
end