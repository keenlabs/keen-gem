require File.expand_path("../spec_helper", __FILE__)

describe "Keen IO API" do
  let(:project_id) { ENV['KEEN_PROJECT_ID'] }
  let(:write_key) { ENV['KEEN_WRITE_KEY'] }

  def wait_for_count(event_collection, count)
    attempts = 0
    while attempts < 30
      break if Keen.count(event_collection, {:timeframe => "this_2_hours"}) == count
      attempts += 1
      sleep(1)
    end
  end

  describe "publishing" do
    let(:collection) { "User posts.new" }
    let(:event_properties) { { "name" => "Bob" } }
    let(:api_success) { { "created" => true } }

    describe "success" do
      it "should return a created status for a valid post" do
        expect(Keen.publish(collection, event_properties)).to eq(api_success)
      end
    end

    describe "failure" do
      it "should raise a not found error if an invalid project id" do
        client = Keen::Client.new(:project_id => "riker", :write_key => "whatever")
        expect {
          client.publish(collection, event_properties)
        }.to raise_error(Keen::NotFoundError)
      end

      it "should succeed if a non-url-safe event collection is specified" do
        expect(Keen.publish("infinite possibilities", event_properties)).to eq(api_success)
      end
    end

    describe "async" do
      # no TLS support in EventMachine on jRuby
      unless defined?(JRUBY_VERSION)

        it "should publish the event and trigger callbacks" do
          EM.run {
            Keen.publish_async(collection, event_properties).callback { |response|
              begin
                expect(response).to eq(api_success)
              ensure
                EM.stop
              end
            }.errback { |error|
              EM.stop
              fail error
            }
          }
        end

        it "should publish to non-url-safe collections" do
          EM.run {
            Keen.publish_async("foo bar", event_properties).callback { |response|
              begin
                expect(response).to eq(api_success)
              ensure
                EM.stop
              end
            }
          }
        end
      end
    end

    describe "batch" do
      it "should publish a batch of events" do
        expect(Keen.publish_batch(
          :batch_signups => [
            { :name => "bob" },
            { :name => "ted" }
          ],
          :batch_purchases => [
            { :price => 30 },
            { :price => 40 }
          ]
        )).to eq({
          "batch_purchases" => [
            { "success" => true },
            { "success" => true }
          ],
          "batch_signups" => [
            { "success" => true },
            { "success"=>true }
          ]})
      end
    end
  end

  describe "batch_async" do
      # no TLS support in EventMachine on jRuby
      unless defined?(JRUBY_VERSION)
        let(:api_success) { {"batch_purchases"=>[{"success"=>true}, {"success"=>true}], "batch_signups"=>[{"success"=>true}, {"success"=>true}]} }
        it "should publish the event and trigger callbacks" do
          EM.run {
            Keen.publish_batch_async(
              :batch_signups => [
                { :name => "bob" },
                { :name => "ted" }
              ],
              :batch_purchases => [
                { :price => 30 },
                { :price => 40 }
              ]).callback { |response|
              begin
                expect(response).to eq(api_success)
              ensure
                EM.stop
              end
            }.errback { |error|
              EM.stop
              fail error
            }
          }
        end
      end
    end

  describe "queries" do
    let(:read_key) { ENV['KEEN_READ_KEY'] }
    let(:event_collection) { @event_collection }
    let(:returns_event_collection) { @returns_event_collection }

    before(:all) do
      @event_collection = "purchases_" + rand(100000).to_s
      @returns_event_collection = "returns_" + rand(100000).to_s

      Keen.publish(@event_collection, {
        :username => "bob",
        :price => 10
      })
      Keen.publish(@event_collection, {
        :username => "ted",
        :price => 20
      })
      Keen.publish(@returns_event_collection, {
        :username => "bob",
        :price => 30
      })

      # poll the count to know when to continue
      wait_for_count(@event_collection, 2)
      wait_for_count(@returns_event_collection, 1)
    end

    it "should return a valid count_unique" do
      expect(Keen.count_unique(event_collection, :timeframe => "this_2_hours", :target_property => "price")).to eq(2)
    end

    it "should return a valid count with group_by" do
      response = Keen.average(event_collection, :timeframe => "this_2_hours", :group_by => "username", :target_property => "price")
      bobs_response = response.select { |result| result["username"] == "bob" }.first
      expect(bobs_response["result"]).to eq(10)
      teds_response = response.select { |result| result["username"] == "ted" }.first
      expect(teds_response["result"]).to eq(20)
    end

    it "should return a valid count with multi-group_by" do
      response = Keen.average(event_collection, :timeframe => "this_2_hours", :group_by => ["username", "price"], :target_property => "price")
      bobs_response = response.select { |result| result["username"] == "bob" }.first
      expect(bobs_response["result"]).to eq(10)
      expect(bobs_response["price"]).to eq(10)
      teds_response = response.select { |result| result["username"] == "ted" }.first
      expect(teds_response["result"]).to eq(20)
      expect(teds_response["price"]).to eq(20)
    end

    it "should return a valid sum" do
      expect(Keen.sum(event_collection, :timeframe => "this_2_hours", :target_property => "price")).to eq(30)
    end

    it "should return a valid minimum" do
      expect(Keen.minimum(event_collection, :timeframe => "this_2_hours", :target_property => "price")).to eq(10)
    end

    it "should return a valid maximum" do
      expect(Keen.maximum(event_collection, :timeframe => "this_2_hours", :target_property => "price")).to eq(20)
    end

    it "should return a valid average" do
      expect(Keen.average(event_collection, :timeframe => "this_2_hours", :target_property => "price")).to eq(15)
    end

    it "should return a valid median" do
      expect(Keen.median(event_collection, :timeframe => "this_2_hours", :target_property => "price")).to eq(10)
    end

    it "should return a valid percentile" do
      expect(Keen.percentile(event_collection, :timeframe => "this_2_hours", :target_property => "price", :percentile => 50)).to eq(10)
      expect(Keen.percentile(event_collection, :timeframe => "this_2_hours", :target_property => "price", :percentile => 100)).to eq(20)
    end

    it "should return a valid select_unique" do
      results = Keen.select_unique(event_collection, :timeframe => "this_2_hours", :target_property => "price")
      expect(results.sort).to eq([10, 20].sort)
    end

    it "should return a valid extraction" do
      results = Keen.extraction(event_collection, :timeframe => "this_2_hours")
      expect(results.length).to eq(2)
      expect(results.all? { |result| result["keen"] }).to be_truthy
      expect(results.map { |result| result["price"] }.sort).to eq([10, 20])
      expect(results.map { |result| result["username"] }.sort).to eq(["bob", "ted"])
    end

    it "should return a valid extraction of one property name" do
      results = Keen.extraction(event_collection, :timeframe => "this_2_hours", :property_names => "price")
      expect(results.length).to eq(2)
      expect(results.any? { |result| result["keen"] }).to be_falsey
      expect(results.map { |result| result["price"] }.sort).to eq([10, 20])
      expect(results.map { |result| result["username"] }.sort).to eq([nil, nil])
    end

    it "should return a valid extraction of more than one property name" do
      results = Keen.extraction(event_collection, :timeframe => "this_2_hours", :property_names => ["price", "username"])
      expect(results.length).to eq(2)
      expect(results.any? { |result| result["keen"] }).to be_falsey
      expect(results.map { |result| result["price"] }.sort).to eq([10, 20])
      expect(results.map { |result| result["username"] }.sort).to eq(["bob", "ted"])
    end

    it "should return a valid funnel" do
      steps = [{
        :event_collection => event_collection,
        :actor_property => "username",
        :timeframe => "this_2_hours"
      }, {
        :event_collection => @returns_event_collection,
        :actor_property => "username",
        :timeframe => "this_2_hours"
      }]
      results = Keen.funnel(:steps => steps)
      expect(results).to eq([2, 1])
    end

    it "should return all keys of valid funnel if full result option is passed" do
      steps = [{
        :timeframe => "this_2_hours",
        :event_collection => event_collection,
        :actor_property => "username"
      }, {
        :timeframe => "this_2_hours",
        :event_collection => @returns_event_collection,
        :actor_property => "username"
      }]
      results = Keen.funnel({ :steps => steps }, { :response => :all_keys })
      expect(results["result"]).to eq([2, 1])
    end

    it "should apply filters" do
      expect(Keen.count(event_collection, :timeframe => "this_2_hours", :filters => [{
        :property_name => "username",
        :operator => "eq",
        :property_value => "ted"
      }])).to eq(1)
    end
  end

  describe "deletes" do
    let(:event_collection) { "delete_test_#{rand(10000)}" }

    before do
      Keen.publish(event_collection, :delete => "me")
      Keen.publish(event_collection, :delete => "you")
      wait_for_count(event_collection, 2)
    end

    it "should delete the event" do
      Keen.delete(event_collection, :filters => [
        { :property_name => "delete", :operator => "eq", :property_value => "me" }
      ])
      wait_for_count(event_collection, 1)
      results = Keen.extraction(event_collection, :timeframe => "this_2_hours")
      expect(results.length).to eq(1)
      expect(results.first["delete"]).to eq("you")
    end
  end

   describe "project methods" do
     let(:event_collection) { "test_collection" }

     describe "event_collections" do
       # requires a project with at least 1 collection
       it "should return the project's collections as JSON" do
         first_collection = Keen.event_collections.first
         expect(first_collection["properties"]["keen.timestamp"]).to eq("datetime")
       end
     end

     describe "project_info" do
       it "should return the project info as JSON" do
         expect(Keen.project_info["url"]).to include(project_id)

       end
     end
   end
end
