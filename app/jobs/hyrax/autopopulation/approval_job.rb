# frozen_string_literal: true

module Hyrax
  module Autopopulation
    # calls Hyrax::Autopopulation::ApprovalJob
    # params [aproval_type] eg multiple or all
    # params :user
    # params :account used by hyku apps
    # params :work_ids when approval_type is multiple ie submitted from check_box ticked
    class ApprovalJob < ApplicationJob
      def perform(approval_type, user, work_ids = nil, account = nil)
        config = Rails.application.config.hyrax_autopopulation

        works = if approval_type == "all"
                  config.query_class.constantize.new(account).fetch_all_draft
                else
                  config.query_class.constantize.new(account).fetch_by_ids(work_ids)
                end

        config.persistence_class.constantize.new(works: works, account: account).approved_works
        autopopulation_complete_notification(user)
      end

      private

        def autopopulation_complete_notification(user)
          url_path = Hyrax::Autopopulation::Engine.routes.url_helpers.work_fetchers_path(anchor: "approved-import")

          user.send_message(user, I18n.t("hyrax.autopopulation.notification.approval_subject"), 
                            I18n.t("hyrax.autopopulation.notification.approval_body", url: url_path))
        end
    end
  end
end
