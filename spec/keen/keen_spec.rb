require File.expand_path("../spec_helper", __FILE__)

describe Keen do
  describe "default client" do
    describe "configuring from the environment" do
      before do
        Keen.instance_variable_set(:@default_client, nil)
        ENV["KEEN_PROJECT_ID"] = "12345"
        ENV["KEEN_WRITE_KEY"] = "abcdewrite"
        ENV["KEEN_READ_KEY"] = "abcderead"
        ENV["KEEN_API_URL"] = "http://fake.keen.io:fakeport"
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

      it "should set an api host from the environment" do
        client.api_url.should == "http://fake.keen.io:fakeport"
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

    [:project_id, :write_key, :read_key, :api_url].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method)
        Keen.send(_method)
      end
    end

    [:project_id=, :write_key=, :read_key=, :api_url=].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method).with("12345")
        Keen.send(_method, "12345")
      end
    end

    [:publish, :publish_async].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method).with("users", {})
        Keen.send(_method, "users", {})
      end
    end

    # pull the query methods list at runtime in order to ensure
    # any new methods have a corresponding delegator
    Keen::Client::QueryingMethods.instance_methods.each do |_method|
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
