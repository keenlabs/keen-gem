require 'spec_helper'

describe Keen::Modeling::Extractors::Enumerable, '#handler?' do
  it 'is handler with a @proc and a array @value' do
    extractor = enum_factory([], Proc.new { 'Test.'})
    expect(extractor).to be_handler
  end

  it 'not handler without a @proc' do
    extractor = enum_factory([], nil)
    expect(extractor).to_not be_handler
  end

  it 'not handler with the incorrect @value type' do
    extractor = enum_factory(Hash.new, Proc.new { title })
    expect(extractor).to_not be_handler
  end
end

describe Keen::Modeling::Extractors::Enumerable, '#extract_value' do
  it 'passes elements in value to Modeler with @proc' do
    item = double(:title => 'Foo')
    extractor = enum_factory([item], Proc.new { title })
    expect(extractor.extract_value).to eq [{ :title => 'Foo' }]
  end
end

def enum_factory(object, proc = nil)
  Keen::Modeling::Extractors::Enumerable.new(object, proc, [])
end
