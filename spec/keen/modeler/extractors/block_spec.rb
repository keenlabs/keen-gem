require 'spec_helper'

describe Keen::Modeling::Extractors::Block, '#valid?' do
  it 'is handler when @proc is assigned' do
    expect(block_factory).to be_handler
  end
end

describe Keen::Modeling::Extractors::Block, '#extract_value' do
  it 'marshals objects through Schema.define' do
    expect(block_factory.extract_value).to eq :title => 'This'
  end
end

def block_factory
  object = double('poro', :title => 'This')
  Keen::Modeling::Extractors::Block.new object, Proc.new { title }, []
end
