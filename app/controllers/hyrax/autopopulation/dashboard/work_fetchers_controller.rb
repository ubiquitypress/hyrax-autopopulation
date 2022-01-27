# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module Dashboard
      class WorkFetchersController < ApplicationController
        before_action :ensure_authorized!
        include ::Hyrax::ThemedLayoutController
        with_themed_layout 'dashboard'

        def index
          add_breadcrumb t(:'hyrax.controls.home'), ::Hyrax::Engine.routes.url_helpers.root_path
          add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), ::Hyrax::Engine.routes.url_helpers.dashboard_path

          @approved_works = []
          @draft_works = []
        end

        # Uses Hyrax::Autopopulation::RecordPersistence class via the config object
        def settings
          if config_object.storage_type == "activerecord"
            config_object.persistence_class.constantize.new.save(autopopulation_settings_params, current_account)
          else
            config_object.persistence_class.constantize.new.save(autopopulation_settings_params)
          end

          flash[:notice] = I18n.t("hyrax.persistence.sucess_saving_orcid_doi")
          redirect_to hyrax_autopopulation.work_fetchers_path
        end

        private

          def autopopulation_settings_params
            params.permit(settings: [:doi_list, :orcid_list, :work_ids, :id])
          end

          def ensure_authorized!
            authorize! :review, :submissions
          end

          def config_object
            Rails.application.config.hyrax_autopopulation
          end
      end
    end
  end
end
