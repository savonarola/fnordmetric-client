require "fnordmetric-client/version"
require 'securerandom'
require 'json'

class FnordmetricClient
  DEFAULT_EVENT_TTL = 3600
  DEFAULT_PREFIX = 'fnordmetric'
  DEFAULT_OVERFLOW_LIMIT = 50000

  def initialize(opts ={})
    @redis = opts[:redis]
    raise ArgumentError, "Bad :redis passed" unless %w{hincrby set lpush expire llen}.all?{|m| @redis.respond_to?(m) }

    @prefix = opts[:prefix] || DEFAULT_PREFIX
    @event_ttl = opts[:event_ttl] || DEFAULT_EVENT_TTL
    @overflow_limit = opts[:overflow_limit] || DEFAULT_OVERFLOW_LIMIT
  end

  def event(type, args = {})
    push_event({'_type' => type.to_s}.merge(args))
  end

  private 

    def key(*elements)
      elements.map(&:to_s).unshift(@prefix).join('-')
    end

    def push_event(event_data)    
      return if @redis.llen(key(:queue)) >= @overflow_limit

      event_id = get_next_uuid
      @redis.hincrby(key(:testdata), "events_received", 1)
      @redis.hincrby(key(:stats), "events_received", 1)
      @redis.set(key(:event, event_id), event_data.to_json)
      @redis.expire(key(:event, event_id), @event_ttl)
      @redis.lpush(key(:queue), event_id)
      event_id
    end
  
    def get_next_uuid
      SecureRandom.hex(16)
    end
end
