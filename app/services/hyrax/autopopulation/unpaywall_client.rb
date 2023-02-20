# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class UnpaywallClient
      attr_accessor :doi

      ENDPOINT = "https://api.unpaywall.org/v2"

      # params [doi] example 10.36001/ijphm.2018.v9i1.2693
      def initialize(doi)
        @doi = doi&.strip
      end

      def data
        fetch_data
        return unless fetch_data&.body&.present? && valid_json?(fetch_data.body)

        @data = JSON.parse(fetch_data.body).presence || {}
      end

      private

        def fetch_data
          @_fetch_data ||= Faraday.get("#{ENDPOINT}/#{doi}", { email: "unpaywall_01@example.com" }, "Content-Type" => "application/json")
        end

        def valid_json?(data)
          return false unless data.is_a? String
          
          JSON.parse(data)
          true
        rescue JSON::ParserError
          false
        end        
    end
  end
end
