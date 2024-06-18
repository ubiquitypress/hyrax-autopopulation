# frozen_string_literal: true
require 'digest'

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

        set_filename(url)
        @user = user
        @account = account
      end

      def save
        file_io = file_io_object
        return unless file_io

        Hyrax::UploadedFile.create(file: file_io, user: user)
      end

      private

      def set_filename(url)
        filename = File.basename(url)

        # If filename is more than 255 characters, modify it
        if filename.length > 255
          filename = File.basename(URI.parse(url).path)

          # If filename is still more than 255 characters after modification, hash and truncate it as last resort
          if filename.length > 255
            hashed_part = Digest::SHA256.hexdigest(filename)[0, 10] # take first 10 chars of hash
            filename = "#{hashed_part}-#{filename[0, 200]}" # truncate original name and append hash
          end
        end

        # Add .pdf extension if filename does not have an extension
        if File.extname(filename).empty?
          filename += ".pdf"
        end

        @filename = filename
      end

      def file_io_object
        begin
          file = Tempfile.new(filename)
          # avoid OpenSSL::SSL::SSLError
          string_io = URI.open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
          file.binmode
          file.write string_io.read

          file_io = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: filename)
          file.close
          file_io
        rescue OpenURI::HTTPError, OpenSSL::SSL::SSLError => e
          Rails.logger.error "#{e} for URL #{url}"
          return nil
        end
      end
    end
  end
end
