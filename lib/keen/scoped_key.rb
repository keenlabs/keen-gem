require 'multi_json'
require 'keen/aes_helper'

module Keen
  class ScopedKey
    include AESHelper
    extend AESHelper

    attr_accessor :api_key
    attr_accessor :data

    class << self
      def decrypt!(api_key, scoped_key)
        encrypted = unhexlify(scoped_key)
        padded_api_key = pad(api_key)
        decrypted = aes256_decrypt(padded_api_key, encrypted)
        data = MultiJson.load(decrypted)
        self.new(api_key, data)
      end
    end

    def initialize(api_key, data)
      self.api_key = api_key
      self.data = data
    end

    def encrypt!
      json_str = MultiJson.dump(self.data)
      padded_api_key = pad(self.api_key)
      encrypted, iv = aes256_encrypt(padded_api_key, json_str)
      hexlify(iv) + hexlify(encrypted)
    end
  end
end
