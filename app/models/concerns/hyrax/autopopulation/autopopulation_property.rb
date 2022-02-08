# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module AutopopulationProperty
      extend ActiveSupport::Concern

      included do
        property :autopopulation_status, predicate: ::RDF::Vocab::SCHEMA.status, multiple: false do |index|
          index.as :stored_searchable
        end
      end
    end
  end
end
