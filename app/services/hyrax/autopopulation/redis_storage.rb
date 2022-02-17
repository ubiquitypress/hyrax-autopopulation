# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class RedisStorage
      attr_accessor :doi_list, :orcid_list, :hyrax_orcid_settings

      def initialize(doi_list: [], orcid_list: [], hyrax_orcid_settings: {})
        @doi_list = doi_list
        @orcid_list = orcid_list
        @hyrax_orcid_settings = hyrax_orcid_settings
      end

      # A wrapper to Redis sadd for saving a SeT & Redis mapped_hmset for saving hash
      #
      def save
        set_array("doi_list", doi_list)
        set_array("orcid_list", orcid_list)
        set_hash("hyrax_orcid_settings", hyrax_orcid_settings)

      rescue Redis::CommandError, Redis::CannotConnectError => exception
        Rails.logger.debug exception.inspect
      end

      # A wrapper for Redis sadd for saving a Set
      # Redis Set is used because automaticaly rejects dupplicates
      def set_array(key, array)
        return if array.blank?
        # Using SET automatically removes duplicates
        value = Set.new(array).to_a
        instance.sadd(key, value)
      end

      # A wrapper for fetching Sets from Redis
      # example keys
      # :doi_list and :orcid_list
      #
      def get_array(key)
        instance.smembers(key)
      end

      def remove_from_array(key, array_list)
        instance.srem(key, array_list)
      end

      # A wrapper for Redis mapped_hmset for saving hash
      # hash example
      #  {"hyrax_orcid_settings": {} }
      #
      def set_hash(key, hash)
        return if hash.blank?
        instance.mapped_hmset(key, hash)
      end

      #  A wrapper for fetching Hash from Redis
      # hash key "hyrax_orcid_settings"
      def get_hash(key)
        instance.hgetall(key)
      end

      # A wrapper for fetching Hash from Redis
      def settings(key)
        instance.scard("array").positive? && instance.smembers(key)
      end

      # A wrapper for deleting from Redis
      def destroy(key)
        instance.del(key)
      end

      private

        # Create a redis instance, this will be moved to an initializer
        def instance
          Redis.current = Redis_instance
        end
    end
  end
end
