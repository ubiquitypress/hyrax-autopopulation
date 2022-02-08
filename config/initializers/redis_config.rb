# frozen_string_literal: true
require 'redis'

Redis_instance = Redis.new(host: ENV["REDIS_HOST"], db: 15)
