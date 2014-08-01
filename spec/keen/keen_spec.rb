require File.expand_path("../spec_helper", __FILE__)

describe Keen do
  describe "default client" do
    describe "configuring from the environment" do
      before do
        Keen.instance_variable_set(:@default_client, nil)
        ENV["KEEN_PROJECT_ID"] = "12345"
        ENV["KEEN_WRITE_KEY"] = "abcdewrite"
        ENV["KEEN_READ_KEY"] = "abcderead"
        ENV["KEEN_MASTER_KEY"] = "lalalala"
        ENV["KEEN_API_URL"] = "http://fake.keen.io:fakeport"
        ENV["KEEN_PROXY_URL"] = "http://proxy.keen.io:proxyport"
        ENV["KEEN_PROXY_TYPE"] = "http"
      end

      let(:client) { Keen.send(:default_client) }

      it "should set a project id from the environment" do
        client.project_id.should == "12345"
      end

      it "should set a write key from the environment" do
        client.write_key.should == "abcdewrite"
      end

      it "should set a read key from the environment" do
        client.read_key.should == "abcderead"
      end

      it "should set a master key from the environment" do
        client.master_key.should == "lalalala"
      end

      it "should set an api host from the environment" do
        client.api_url.should == "http://fake.keen.io:fakeport"
      end

      it "should set an proxy host from the environment" do
        client.proxy_url.should == "http://proxy.keen.io:proxyport"
      end

      it "should set an proxy type from the environment" do
        client.proxy_type.should == "http"
      end
    end
  end

  describe "Keen delegation" do
    it "should memoize the default client, retaining settings" do
      Keen.project_id = "new-abcde"
      Keen.project_id.should == "new-abcde"
    end

    after do
      Keen.instance_variable_set(:@default_client, nil)
    end
  end

  describe "forwardable" do
    before do
      @default_client = double("client")
      Keen.stub(:default_client).and_return(@default_client)
    end

    [:project_id, :write_key, :read_key, :api_url, :proxy_url, :proxy_type].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method)
        Keen.send(_method)
      end
    end

    [:project_id, :write_key, :read_key, :master_key, :api_url].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method)
        Keen.send(_method)
      end
    end

    [:project_id=, :write_key=, :read_key=, :master_key=, :api_url=].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method).with("12345")
        Keen.send(_method, "12345")
      end
    end

    [:publish, :publish_async, :publish_batch, :publish_batch_async].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method).with("users", {})
        Keen.send(_method, "users", {})
      end
    end

    # pull the query methods list at runtime in order to ensure
    # any new methods have a corresponding delegator
    Keen::Client::QueryingMethods.instance_methods.each do |_method|
      next if _method == :query
      it "should forward the #{_method} query method" do
        @default_client.should_receive(_method).with("users", {})
        Keen.send(_method, "users", {})
      end
    end
  end

  describe "logger" do
    it "should be set to info" do
      Keen.logger.level.should == Logger::INFO
    end
  end
end
