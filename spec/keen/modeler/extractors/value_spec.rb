require 'spec_helper'

describe Keen::Modeling::Extractors::Value, '#handler?' do
  it 'returns true' do
    extractor = Keen::Modeling::Extractors::Value.new('test', [], nil)
    expect(extractor).to be_handler
  end
end

describe Keen::Modeling::Extractors::Value, '#extract_value' do
  it 'returns @value unmolested' do
    extractor = Keen::Modeling::Extractors::Value.new('test', [], nil)
    expect(extractor.extract_value).to eq 'test'
  end
end
