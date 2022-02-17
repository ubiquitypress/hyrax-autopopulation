# frozen_string_literal: true

module Hyrax
  module Autopopulation
    # calls Hyrax::Autopopulation::ApprovalJob
    # params [aproval_type] eg multiple or all
    # params :user
    # params :account used by hyku apps
    # params :work_ids when approval_type is multiple ie submitted from check_box ticked
    class RejectionJob < ApplicationJob
      def perform(user, work_ids = nil, account = nil)
        config = Rails.application.config.hyrax_autopopulation

        works = config.query_class.constantize.new(account).fetch_by_ids(work_ids)
        klass = config.persistence_class.constantize.new(works: works, account: account)
        klass.save_rejected_ids.delete_rejected_works

        autopopulation_complete_notification(user)
      end

      private

        def autopopulation_complete_notification(user)
          user.send_message(user, I18n.t("hyrax.autopopulation.notification.rejection_subject"), I18n.t("hyrax.autopopulation.notification.rejection_body"))
        end
    end
  end
end
