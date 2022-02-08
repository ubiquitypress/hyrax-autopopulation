# frozen_string_literal: true
module Hyrax
  module Autopopulation
    module DoiProperty
      extend ActiveSupport::Concern

      included do
        # This check is needed because the Hyrax::DOI
        unless Object.const_defined?("Hyrax::DOI")
          property :doi, predicate: ::RDF::Vocab::BIBO.doi, multiple: true do |index|
            index.as :stored_sortable
          end
        end
      end
    end
  end
end
