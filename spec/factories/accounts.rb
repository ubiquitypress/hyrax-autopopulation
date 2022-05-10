# frozen_string_literal: true
FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "tenant#{n}" }
    sequence(:cname) { |n| "repo#{n}.hyku.docker" }
  end
end
