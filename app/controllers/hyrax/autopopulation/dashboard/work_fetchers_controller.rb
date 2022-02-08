# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module Dashboard
      class WorkFetchersController < ApplicationController
        before_action :ensure_authorized!
        # include ::Hyrax::ThemedLayoutController
        # with_themed_layout "dashboard"

        def index
          add_breadcrumb t("hyrax.controls.home"), ::Hyrax::Engine.routes.url_helpers.root_path
          add_breadcrumb t("hyrax.dashboard.breadcrumbs.admin"), ::Hyrax::Engine.routes.url_helpers.dashboard_path

          # The config object sets Hyrax::Autopopulation::ImportedWorkStatusService
          @approved_works = config_object.imported_work_status_service.constantize.new("approved")
          @draft_works = config_object.imported_work_status_service.constantize.new("draft")
        end

        # POST / PATCH requets
        # Uses Hyrax::Autopopulation::RecordPersistence class via the config object
        # Note * splits a array into multiple arguments
        # example of the value returned by args
        # [autopopulation_settings_params, current_account]
        #
        def settings
          args = pass_arguments_by_storage_type([autopopulation_settings_params])
          config_object.persistence_class.constantize.new.save(*args)

          flash[:notice] = I18n.t("hyrax.autopopulation.persistence.success_saving_orcid_doi")
          redirect_to hyrax_autopopulation.work_fetchers_path
        end

        # POST request
        # orchestartor is defined as Hyrax::Autopopulation::Orchestrator
        #  Hyrax::Autopopulation::Orchestrator.new(user: current_user).run_with_doi
        # Note ** splits a hash into multiple arguments for keyword arguments
        # Example of the expected value retruned by  args
        # {user: current_user, account: current_account}
        # Hyrax::Autopopulation::FetchAndSaveWorkMetadata
        def fetch_with_doi
          args = pass_arguments_by_storage_type(fetch_doi_klass: config_object.query_class,
                                                user: current_user)
          config_object.work_fetcher_job.constantize.perform_later(args)

          flash[:notice] = I18n.t("hyrax.autopopulation.persistence.doi_fetch")
          redirect_to hyrax_autopopulation.work_fetchers_path
        end

        # POST request
        def fetch_with_orcid
          args = pass_arguments_by_storage_type(fetch_doi_klass: config_object.orcid_client,
                                                user: current_user)
          config_object.work_fetcher_job.constantize.perform_later(args)

          flash[:notice] = I18n.t("hyrax.autopopulation.persistence.orcid_fetch")
          redirect_to hyrax_autopopulation.work_fetchers_path
        end

        # PUT request
        # defined in config as ::Hyrax::Autopopulation::RecordPersistence
        def approve_all
          args = pass_arguments_by_storage_type(["all", current_user])
          config_object.approval_job.constantize.perform_later(*args)

          flash[:notice] = I18n.t("hyrax.autopopulation.persistence.approve")
          redirect_to hyrax_autopopulation.work_fetchers_path
        end

        # PUT request
        # calls Hyrax::Autopopulation::ApprovalJob
        # with params :approval_type eg "all" and "multiple"
        # params :user
        # params :account used by hyku apps
        # params :work_ids ie submitted from check_box ticked
        def approve_multiple
          args = pass_arguments_by_storage_type(["multiple", current_user, params["work_ids"]])
          config_object.approval_job.constantize.perform_later(*args)

          flash[:notice] = I18n.t("hyrax.autopopulation.persistence.approve")
          redirect_to hyrax_autopopulation.work_fetchers_path
        end

        private

          def autopopulation_settings_params
            if config_object.storage_type == "redis"
              params.permit(settings: %i[doi_list orcid_list work_ids id])
            else
              params.require(:account).permit(settings: %i[doi_list orcid_list work_ids id])
            end
          end

          def ensure_authorized!
            authorize! :review, :submissions
          end

          def config_object
            Rails.application.config.hyrax_autopopulation
          end

          # We are using array splat to pass multiple arguments to a method call
          # the method below add an additional arguments depending on whether records are stored i redis or activerecord
          #
          # for regular argument the splat expects
          # [autopopulation_settings_params]
          #
          # and for key word arguments it expetcts a hash
          #   {user: current_user}
          #
          def pass_arguments_by_storage_type(value)
            if config_object.storage_type == "activerecord"
              value.is_a?(Hash) ? value.merge!(account: current_account) : (Array(value) << current_account)
            else
              value
            end
          end
      end
    end
  end
end
