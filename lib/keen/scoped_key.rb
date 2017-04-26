require 'multi_json'
require 'keen/aes_helper'
require 'keen/aes_helper_old'

module Keen
  class ScopedKey

    attr_accessor :api_key
    attr_accessor :data

    class << self
      def decrypt!(api_key, scoped_key)
        if api_key.length == 64
          puts 'new'
          decrypted = Keen::AESHelper.aes256_decrypt(api_key, scoped_key)
        else
          puts 'old'
          decrypted = Keen::AESHelperOld.aes256_decrypt(api_key, scoped_key)
        end
        puts 'load json'
        data = MultiJson.load(decrypted)
        puts 'return new self'
        self.new(api_key, data)
      end
    end

    def initialize(api_key, data)
      self.api_key = api_key
      self.data = data
    end

    def encrypt!(iv = nil)
      puts 'start encrypt'
      json_str = MultiJson.dump(self.data)
      puts 'got json'
      if self.api_key.length == 64
        Keen::AESHelper.aes256_encrypt(self.api_key, json_str, iv)
      else
        puts 'old'
        Keen::AESHelperOld.aes256_encrypt(self.api_key, json_str, iv)
      end
    end
  end
end
