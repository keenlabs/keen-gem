require 'spec_helper'

describe Keen::ScopedKey do
  let(:api_key) { "ab428324dbdbcfe744" }
  let(:bad_api_key) { "badbadbadbad" }
  let(:data) { {
   "filters" => [{
      "property_name" => "accountId",
      "operator" => "eq",
      "property_value" => "123456"
    }]
  }}
  let(:new_scoped_key) { Keen::ScopedKey.new(api_key, data) }

  describe "constructor" do
    it "should retain the api_key" do
      new_scoped_key.api_key.should == api_key
    end

    it "should retain the data" do
      new_scoped_key.data.should == data
    end
  end

  describe "encrypt! and decrypt!" do
    it "should encrypt and hex encode the data using the api key" do
      encrypted_str = new_scoped_key.encrypt!
      other_api_key = Keen::ScopedKey.decrypt!(api_key, encrypted_str)
      other_api_key.data.should == data
    end

    it "should not decrypt the scoped key with a bad api key" do
      encrypted_str = new_scoped_key.encrypt!
      expect {
        other_api_key = Keen::ScopedKey.decrypt!(bad_api_key, encrypted_str)
      }.to raise_error(OpenSSL::Cipher::CipherError)
    end
  end
end
