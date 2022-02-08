# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class ImportedWorkStatusService
      attr_accessor :filter_term

      # @param filter_term [String] a term to query against autopopulation_status_tesim
      # example "draft" or "approved"
      def initialize(filter_term)
        @filter_term = filter_term
      end

      def each
        return enum_for(:each) unless block_given?

        solr_documents.each do |doc|
          yield doc
        end
      end

      def search_solr
        ActiveFedora::SolrService.query(query, rows: 1_000_000)
      end

      private

        # @return [Hash<String,SolrDocument>] a hash of id to solr document
        def solr_documents
          search_solr.map { |result| ::SolrDocument.new(result) }
        end

        def query
          "_query_:\"{!raw f=autopopulation_status_tesim}#{filter_term}\""
        end
    end
  end
end
