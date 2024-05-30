# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module WorkTypeMapper
      extend ActiveSupport::Concern

      DEFAULT_WORK_TYPE = "GenericWork"

      private

      def map_work_type(crossref_type, crossref_hyku_mappings)
        if crossref_hyku_mappings.key?(crossref_type)
          klass_name = crossref_hyku_mappings[crossref_type]
          @mapped_work_type = klass_name if class_exists?(klass_name)
        end
        @mapped_work_type.present? ? @mapped_work_type : (DEFAULT_WORK_TYPE)
      end

        def class_exists?(class_name)
          klass = HykuAddons.const_get(class_name)
          klass.is_a?(Class)
        rescue NameError
          false
        end
    end
  end
end
