# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class CreateWork
      include Hyrax::Autopopulation::WorkTypeMapper
      attr_accessor :attributes, :user, :account, :pdf_url, :uploaded_files, :admin_set
      ADMINSET_NAME = "autopopulation".freeze

      # params [attributes] is a hash constructed from a crossref response that has been crosswalked by a custom Bolognese writer
      # example using the doi 10.1117/12.2004063
      # response = Bolognese::Metadata.new(input: '10.1117/12.2004063', from: "crossref")
      # attributes = response.build_work_actor_attributes
      #
      def initialize(attributes, user, account = nil)
        AccountElevator.switch!(account&.cname) if Rails.application.config.hyrax_autopopulation.active_record?

        @account = account
        @user = user
        puts "LOG_ATTRIBUTES #{attributes.inspect}"

        # set the work state to :inactive which also suppresses or ensures it is not
        # returned by search until approved
        attributes[:state] = Vocab::FedoraResourceStatus.inactive
        # This is not a property of any work, so it cannot be passed to the actor
        @pdf_url = attributes.delete(:unpaywall_pdf_url)
        # create Hyrax::Uploaded file object if a pdf url exists
        pdf_url.present? && uploaded_file

        # create or set the admin_set to be used for this work
        attributes[:admin_set_id] = get_admin_set.id if get_admin_set.present?
        @attributes = attributes
      end

      def save
        # saves work
        # This returns true when the work is aved or false
        actor.create(actor_environment)
        # attach files to the work
        AttachFilesToWorkJob.perform_later(actor_environment.curation_concern, @uploaded_files) if @uploaded_files.present?
      end

      private

        def actor
          Hyrax::CurationConcern.actor
        end

        def actor_environment
          klass = Hyrax::Actors::Environment
          puts "LOG_ATTRIBUTES #{@attributes.inspect}"
          crossref_work_type = fetch_crossref_work_type(@attributes[:doi])
          crossref_work_type = crossref_work_type[:crossref_work_type]
          puts "LOG_ATTRIBUTES #{crossref_work_type.inspect}"

          @mapped_work_type = map_work_type(crossref_work_type)
          @_actor_environment ||= if Rails.application.config.hyrax_autopopulation.active_record?
                                    klass.new(Object.const_get(@mapped_work_type).new, ::Ability.new(user), attributes)
                                  else
                                    # Remove fields not defined by Hyrax
                                    keys = %i[date_published editor]
                                    new_attributes = attributes.except(*keys)
                                    klass.new(Object.const_get(@mapped_work_type).new, ::Ability.new(user), new_attributes)
                                  end
        end

        def uploaded_file
          # return unless pdf_url.present?

          file_class = Rails.application.config.hyrax_autopopulation.create_file_class.constantize
          file = file_class.new(pdf_url, user, account).save

          # If a file was saved set @uploaded_files so we can pas it to AttachFilesToWorkJob later
          @uploaded_files = [file] if file.is_a?(Hyrax::UploadedFile)
        end

        def get_admin_set
          return @admin_set if @admin_set.present?

          @get_admin_set ||= AdminSet.where(title: ADMINSET_NAME)&.first
          if @get_admin_set.present?
            @admin_set = @get_admin_set
          else
            create_admin_set
          end
        end

        # creates admin_set for autopopulated works only if non exists
        def create_admin_set
          new_admin_set = AdminSet.new(id: SecureRandom.uuid, title: Array.wrap(ADMINSET_NAME))
          admin_set_create_service = ::Hyrax::AdminSetCreateService.new(admin_set: new_admin_set, creating_user: nil).create
          @admin_set = admin_set_create_service.admin_set
        end

        def fetch_crossref_work_type(doi)
          config.crossref_bolognese_client.constantize.new(input: doi)&.build_crossref_work_type
        end

        def config
          Rails.application.config.hyrax_autopopulation
        end
    end
  end
end
