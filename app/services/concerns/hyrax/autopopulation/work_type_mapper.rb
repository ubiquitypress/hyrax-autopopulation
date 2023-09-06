# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module WorkTypeMapper
      extend ActiveSupport::Concern

      private

        def mapped_work_type
          crossref_type = meta["type"]
          crossref_hyku_mappings = @account.settings["crossref_hyku_mappings"]

          if crossref_hyku_mappings.key?(crossref_type)
            klass_name = crossref_hyku_mappings[crossref_type].camelize.constantize
            return klass_name if class_exists?(klass_name)
          end

          GenericWork
        end

        def class_exists?(class_name)
          klass = Hyrax::Collections.const_get(class_name)
          klass.is_a?(Class)
        rescue NameError
          false
        end
    end
  end
end
