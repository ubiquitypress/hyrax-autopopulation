# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module WorkTypeMapper
      extend ActiveSupport::Concern

      private

        def map_work_type(crossref_type)
          @crossref_hyku_mappings = Site.account.settings&.dig("crossref_hyku_mappings")

          puts "LOG_crossref_type #{crossref_type.inspect}"
          puts "LOG_crossref_hyku_mappings #{@crossref_hyku_mappings.inspect}"

          if @crossref_hyku_mappings.key?(crossref_type)
            klass_name = @crossref_hyku_mappings[crossref_type]
            puts "LOG_klass_name #{klass_name.inspect}"
            return @mapped_work_type = klass_name if class_exists?(klass_name)
          end

          @mapped_work_type = "GenericWork"
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
