# frozen_string_literal: true
module Hyrax
  module Autopopulation
    module ApplicationHelper
      # rubocop:disable Style/IfUnlessModifier
      unless Object.const_defined?(:HykuAddons) || Object.const_defined?(:HykuAddons)
        include Hyrax::HyraxHelperBehavior
      end
      # rubocop:enable Style/IfUnlessModifier
    end
  end
end
