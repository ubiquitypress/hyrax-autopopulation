# frozen_string_literal: true
FactoryBot.define do
  factory :account do
    sequence(:cname) { |n| "repor#{n}.hyku.docker" }
  end
end
