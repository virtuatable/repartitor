FactoryGirl.define do
  factory :empty_campaign, class: Arkaan::Campaign do
    factory :campaign do
      _id 'campaign_id'
      title 'test_title'
      description 'A longer description of the campaign'
      is_private true
      tags ['test_tag']
    end
  end
end