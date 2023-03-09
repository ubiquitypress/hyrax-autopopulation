# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module ActivateObjectOverride
      extend ActiveSupport::Concern
      class_methods do
        def call(target:, **)
          # Since we are using the default workflow, we need to ensure autopopulated works with draft status have a state of inactive to
          # hide them from dashboard and search till approved

          puts "LOG_TARGET_STATE_BEFORE_AUTOPOPULATION_STATUS_CHECK #{target.state}"
          puts "LOG_AUTOPOPULATION_STATUS_BEFORE_AUTOPOPULATION_STATUS_CHECK #{target&.autopopulation_status}"
          return target.state = Vocab::FedoraResourceStatus.inactive if target&.autopopulation_status == "draft"
          puts "LOG_TARGET_STATE_AFTER_AUTOPOPULATION_STATUS_CHECK #{target.state}"

          target.state = Vocab::FedoraResourceStatus.active
        end
      end
    end
  end
end
