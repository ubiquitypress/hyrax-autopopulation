# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module DoiActorOverride
      extend ActiveSupport::Concern

      private

        def doi_enabled_work_type?(work)
          return false if work.autopopulation_status == "draft"

          work.class.ancestors.include? Hyrax::DOI::DOIBehavior
        end

    end
  end
end
