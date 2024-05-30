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

        return unless @url.present?

        @filename = URI.parse(url).path.split('/').last # Extract file name from url
        @user = user
        @account = account
      end

      def save
        file_io = file_io_object
        Hyrax::UploadedFile.create(file: file_io, user: user)
      end

      private

        def file_io_object
          file = Tempfile.new(filename)
          # avoid OpenSSL::SSL::SSLError
          string_io = URI.open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
          file.binmode
          file.write string_io.read

          file_io = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: filename)
          file.close
          file_io

        rescue OpenURI::HTTPError, OpenSSL::SSL::SSLError => e
          Rails.logger.info "#{e} for this url #{url}"
        end
    end
  end
end
