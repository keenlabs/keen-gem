require 'keen/modeling/extractors/abstract'
require 'keen/modeling/extractors/block'
require 'keen/modeling/extractors/enumerable'
require 'keen/modeling/extractors/proc'
require 'keen/modeling/extractors/value'
require 'keen/modeling/value_extractor'
require 'keen/modeling/option_key'
require 'keen/modeling/marshaller'

module Keen
  class Modeler
    attr_reader :object

    def self.define(object, &block)
      new(object).define(&block)
    end

    def initialize(object)
      @object = object
    end

    def define(&block)
      fail 'Definition block not provided' unless block
      marshaller = Modeling::Marshaller.new(object)
      marshaller.instance_eval(&block)

      marshaller
    end
  end
end
