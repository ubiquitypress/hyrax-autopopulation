# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class WorkFetcherJob < ApplicationJob
      EXCEPTIONS = [RSolr::Error, Faraday::Error, Ldp::Gone, Redis::CannotConnectError,
                    MiniMagick::Invalid, Errno::EADDRNOTAVAIL, URI::InvalidURIError, TypeError,
                    ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid].freeze

      rescue_from(*EXCEPTIONS) do |exception|
        Rails.logger.debug "from work_fetcher_job #{exception.inspect}"
      end

      # params id_type eg "doi" or "orcid"
      # args for hyrax app example
      # {user: current_user}
      # args for hyku app example
      # {user: current_user, account: current_account}
      #
      def perform(args)
        orchestrator = Rails.application.config.hyrax_autopopulation.orchestrator_class
        puts "LOG_orchestrator: #{orchestrator.inspect}"
        instance = orchestrator.constantize.new(**args)
        puts "LOG_instance: #{instance.inspect}"
        instance.fetch_doi_list
        instance.create_records
      end
    end
  end
end
