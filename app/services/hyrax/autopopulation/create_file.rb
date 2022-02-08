# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class CreateFile
      attr_accessor :url, :work, :user, :account, :filename

      # params :url is the remote file localtion from unpaywall response
      #
      def initialize(url, user, work = nil, account = nil)
        AccountElevator.switch!(account.cname) if Rails.application.config.hyrax_autopopulation.storage_type == "activerecord"

        @url = url&.strip

        return unless @url.present?

        @filename = File.basename(url)
        @work = work
        @user = user
        @account = account
      end

      def save
        return if a_dulpicate?

        file_io = file_io_object
        Hyrax::UploadedFile.create(file: file_io, user: user)
      end

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

      private

        def a_dulpicate?
          return unless work.try(:file_sets).try(:present?)

          file_titles = work.file_sets.map { |file_set| file_set.title.first }
          file_titles.include?(filename)
        end
    end
  end
end