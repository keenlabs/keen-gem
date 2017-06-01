require 'multi_json'
require 'keen/aes_helper'
require 'keen/aes_helper_old'

module Keen
  # <b>DEPRECATED:</b> Please use <tt>access keys</tt> instead.
  class ScopedKey

    attr_accessor :api_key
    attr_accessor :data

    class << self
      def decrypt!(api_key, scoped_key)
        if api_key.length == 64
          decrypted = Keen::AESHelper.aes256_decrypt(api_key, scoped_key)
        else
          decrypted = Keen::AESHelperOld.aes256_decrypt(api_key, scoped_key)
        end
        data = MultiJson.load(decrypted)
        self.new(api_key, data)
      end
    end

    def initialize(api_key, data)
      self.api_key = api_key
      self.data = data
    end

    def encrypt!(iv = nil)
      warn "[DEPRECATION] Scoped keys are deprecated. Please use `access_keys` instead."

      json_str = MultiJson.dump(self.data)
      if self.api_key.length == 64
        Keen::AESHelper.aes256_encrypt(self.api_key, json_str, iv)
      else
        Keen::AESHelperOld.aes256_encrypt(self.api_key, json_str, iv)
      end
    end
  end
end
