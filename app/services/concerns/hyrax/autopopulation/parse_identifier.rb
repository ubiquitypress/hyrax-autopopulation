# frozen_string_literal: true

module Hyrax
  module Autopopulation
    module ParseIdentifier
      extend ActiveSupport::Concern

      private

        # slashes url and returms just the doi or orcid ids
        # params ids is an array of doi or orcid not mixed
        # eg of array of doi
        # ["10.36001/ijphm.2018.v9i1.2693", https://handle.test.datacite.org/10.80090/nphc-8y78]
        # example of array of orcid
        # [" 0000-0002-0787-9826", "https://sandbox.orcid.org/0000-0002-0491-7882"]
        #
        def remove_url_from_ids(ids)
          new_ids = ids.map do |id|
            slice_out_id_from_url(id)
          end.compact

          new_ids.presence || []
        end

        # Prevent Solr bad request error by handling corner cases when doi is a url eg
        # https://handle.test.datacite.org/10.80090/nphc-8y78
        # and return
        # 10.80090/nphc-8y78
        def slice_out_id_from_url(id)
          id_url = Addressable::URI.parse(id&.strip)

          return id unless id_url&.scheme

          id_url&.path&.slice!(0)
          id_url&.path&.presence || nil
        end
    end
  end
end
