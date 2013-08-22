require 'spec_helper'

describe FnordmetricClient do
  let(:redis){ MockRedis.new }
  let(:prefix){ 'pref' }
  let(:event_ttl){ 10 }
  let(:overflow_limit){ 5 }
  let(:client){ described_class.new(:redis => redis, :prefix => prefix, :overflow_limit => overflow_limit, :event_ttl => event_ttl) }

  before(:each) do
    redis.flushall
  end

  describe "#new" do
    it "should raise exception when redis is not passed" do
      expect{ described_class.new({:redis => 123}) }.to raise_exception(ArgumentError)
      expect{ described_class.new({}) }.to raise_exception(ArgumentError)
    end
  end

  describe '#event' do
    
    context "when redis is not overflown" do
      it "should put event id into queue" do
        client.event('foo', :some => 'payload')
        redis.llen("#{prefix}-queue").to_i.should == 1
      end
      
      it "should put event data by the key pushed into queue" do
        client.event('foo', :some => 'payload')
        event_id = redis.lrange("#{prefix}-queue", 0, 1).first
        event_data_json = redis.get "#{prefix}-event-#{event_id}"
        event_data_json.should_not be_nil
        event_data = JSON.parse(event_data_json)
        event_data.should == {'_type' => 'foo', 'some' => 'payload'}
      end

      it "should increase stat counters" do
        client.event('foo', :some => 'payload')
        redis.hget("#{prefix}-stats", "events_received").to_i.should == 1
        redis.hget("#{prefix}-testdata", "events_received").to_i.should == 1
        client.event('foo', :some => 'payload')
        redis.hget("#{prefix}-stats", "events_received").to_i.should == 2
        redis.hget("#{prefix}-testdata", "events_received").to_i.should == 2
      end

      it "should generate different event ids" do
        client.event('foo', :some => 'payload')
        client.event('foo', :some => 'payload')
        redis.llen("#{prefix}-queue").to_i.should == 2
      end

      it "should expire event data" do
        client.event('foo', :some => 'payload')
        event_id = redis.lrange("#{prefix}-queue", 0, 1).first
        event_data_json = redis.get "#{prefix}-event-#{event_id}"
        event_data_json.should_not be_nil
        Timecop.freeze(Time.now + event_ttl + 1) do
          event_data_json = redis.get "#{prefix}-event-#{event_id}"
          event_data_json.should be_nil
        end
      end

    end

    context "when redis is overflown" do
      it "should not send events to queue" do
        overflow_limit.times{ redis.lpush "#{prefix}-queue", "xxx" }
        client.event('foo', :some => 'payload')
        redis.llen("#{prefix}-queue").to_i.should == overflow_limit
        redis.keys('*').size.should == 1
      end
    end
  end
end


