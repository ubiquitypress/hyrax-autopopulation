# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class CreateWork
      attr_accessor :attributes, :user, :account, :pdf_url

      # params [attributes] is a hash constructed from a crossref response that has been crosswalked by a custom Bolognese writer
      # example using the doi 10.1117/12.2004063
      # response = Bolognese::Metadata.new(input: '10.1117/12.2004063', from: "crossref")
      # attributes = response.build_work_actor_attributes
      #
      def initialize(attributes, user, account = nil)
        AccountElevator.switch!(account&.cname) if Rails.application.config.hyrax_autopopulation.active_record?

        @account = account
        @user = user

        # This is not a property of any work, so it cannot be passed to the actor
        @pdf_url = attributes.delete(:unpaywall_pdf_url)

        pdf_url.present? && uploaded_file.present? && attributes.merge!(uploaded_files: uploaded_file)
        @attributes = attributes
      end

      def save
        # saves work
        # This returns true when the work is aved or false
        actor.create(actor_environment)
      end

      private

        def actor
          Hyrax::CurationConcern.actor
        end

        def actor_environment
          klass = Hyrax::Actors::Environment

          @_actor_environment ||= if Rails.application.config.hyrax_autopopulation.active_record?
                                    klass.new(GenericWork.new, ::Ability.new(user), attributes)
                                  else
                                    # Remove fields not defined by Hyrax
                                    keys = %i[date_published editor]
                                    new_attributes = attributes.except(*keys)
                                    klass.new(GenericWork.new, ::Ability.new(user), new_attributes)
                                  end
        end

        def uploaded_file
          # return unless pdf_url.present?
          file_class = Rails.application.config.hyrax_autopopulation.create_file_class.constantize
          file = file_class.new(pdf_url, user, account).save
          file.is_a?(Hyrax::UploadedFile) ? [file.id] : false
        end
    end
  end
end
