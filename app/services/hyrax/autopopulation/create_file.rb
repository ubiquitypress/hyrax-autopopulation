# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class CreateFile
      attr_accessor :url, :user, :account, :filename

      # params :url is the remote file localtion from unpaywall response
      #
      def initialize(url, user, account = nil)
        AccountElevator.switch!(account.cname) if Rails.application.config.hyrax_autopopulation.active_record?

        @url = url&.strip

        unless @url.present?
          Rails.logger.error "URL was not provided."
          return
        end

        Rails.logger.info "LOG_URL passed to CreateFile initializer: #{@url}"
        begin
          @filename = File.basename(URI.parse(url).path)
          Rails.logger.info "LOG_Filename after extraction: #{@filename}"
        rescue => e
          Rails.logger.error "Failed to extract a filename from the url: #{@url}. Error: #{e}"
          return
        end
        # Reconstruct filename code here
        @user = user
        @account = account
      end

      def save
        file_io = file_io_object
        Hyrax::UploadedFile.create(file: file_io, user: user)
      end

      private

        def file_io_object
          begin
            file = Tempfile.new(filename)
            string_io = URI.open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
            file.binmode
            file.write string_io.read

            file_io = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: filename)
            file.close
            file_io
          rescue OpenURI::HTTPError => e
            Rails.logger.error "Failed to open URL #{url}. Error: #{e}"

            # Here we only log the 400 Bad Request error
            if e.message.include?('400 Bad Request')
              Rails.logger.error "Received 400 Bad Request error. The token is likely expired."
            end
          rescue OpenSSL::SSL::SSLError => e
            Rails.logger.error "#{e} for this url #{url}"
          end
      end
    end
  end
end
