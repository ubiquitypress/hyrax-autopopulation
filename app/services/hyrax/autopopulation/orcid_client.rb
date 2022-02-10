# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class OrcidClient
      OAUTH_TOKEN_ENDPOINT = "https://sandbox.orcid.org/oauth/token"
      ORCID_API_URL = "https://pub.sandbox.orcid.org/v2.1"
      ENDPOINT = "works"

      attr_accessor :account

      def initialize(account = nil)
        @account = account
      end

      # returns an array of doi extracted from the works in orcid
      # example %w[10.1038/srep15737 10.1038/nature12373 10.1117/12.2004063]
      def fetch_doi_list
        fetch_and_store_access_token unless check_token_presence?
        extract_doi.presence || []
      end

      private

        def extract_doi
          extract_response_ids&.flatten&.collect do |item|
            item["external-id-value"] if item["external-id-type"] == "doi"
          end.compact
        end

        def check_token_presence?
          token_in_redis = config.redis_storage_class.constantize.new.get_hash("hyrax_orcid_settings")&.dig("access_token")
          token_in_postgres = config.storage_type == "activerecord" && account.settings&.dig("hyrax_orcid_settings", "access_token")
          (token_in_redis || token_in_postgres).present? ? true : false
        end

        def client_credentials
          if config.storage_type == "redis"
            {
              client_id: ENV["ORCID_CLIENT_ID"], client_secret: ENV["ORCID_CLIENT_SECRET"],
              grant_type: "client_credentials", scope: "/read-public"
            }
          else
            {
              client_id: account.settings&.dig("hyrax_orcid_settings")&.dig(:client_id),
              client_secret: account.settings&.dig("hyrax_orcid_settings")&.dig(:client_secret),
              grant_type: "client_credentials", scope: "/read-public"
            }
          end
        end

        # use values from pesisatence
        def headers
          token = if config.storage_type == "redis"
                    config.redis_storage_class.constantize.new.get_hash("hyrax_orcid_settings")&.dig("access_token")
                  else
                    account.settings&.dig("hyrax_orcid_settings")&.dig(:access_token)
                  end

          { "authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
        end

        def fetch_and_store_access_token
          response = Faraday.post(OAUTH_TOKEN_ENDPOINT, client_credentials.to_query, "Accept" => "application/json")

          return unless response.success?

          hash = JSON.parse(response.body)
          data = { "settings" => { "hyrax_orcid_settings" => hash } }

          config.persistence_class.constantize.new.save(data, account)
        end

        def orcid_from_db
          config.query_class.constantize.new(account).orcid_from_db
        end

        def fetch_works_with_auth
          @_fetch_works_with_auth = orcid_from_db&.map do |id|
            Faraday.send(:get, "#{ORCID_API_URL}/#{id}/#{ENDPOINT}", nil, headers)
          end
        end

        def parsed_response
          fetch_works_with_auth.map do |api_response|
            next unless api_response.success?
            JSON.parse(api_response.body)
          end.compact
        end

        def extract_response_ids
          parsed_response.map do |work|
            work&.dig("group")&.map do |item|
              item["external-ids"]["external-id"]
            end
          end.compact
        end

        def config
          Rails.application.config.hyrax_autopopulation
        end
    end
  end
end
