require File.expand_path("../spec_helper", __FILE__)

describe Keen do
  describe "default client" do
    describe "configuring from the environment" do
      before do
        ENV["KEEN_PROJECT_ID"] = "12345"
        ENV["KEEN_API_KEY"] = "abcde"
      end

      let(:client) { Keen.send(:default_client) }

      it "should set a project id from the environment" do
        client.project_id.should == "12345"
      end

      it "should set an api key from the environment" do
        client.api_key.should == "abcde"
      end

      after do
        ENV["KEEN_PROJECT_ID"] = nil
        ENV["KEEN_API_KEY"] = nil
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

    [:project_id, :api_key].each do |_method|
      it "should forward the #{_method} method" do
        @default_client.should_receive(_method)
        Keen.send(_method)
      end
    end

    [:project_id=, :api_key=].each do |_method|
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
  end

  describe "logger" do
    it "should be set to info" do
      Keen.logger.level.should == Logger::INFO
    end
  end
end
