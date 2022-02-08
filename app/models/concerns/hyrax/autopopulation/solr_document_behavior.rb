# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module SolrDocumentBehavior
      extend ActiveSupport::Concern

      included do
        attribute :autopopulation_status, ::SolrDocument::Solr::String, "autopopulation_status_tesim"
        Object.const_defined?(:HykuAddons) && (attribute :doi, ::SolrDocument::Solr::String, "doi_ssi")
      end
    end
  end
end
