require 'spec_helper'

describe Keen::Modeling::Extractors::Proc, '#handler?' do
  it 'is handler when a proc is passed in as the first argument' do
    expect(proc_factory).to be_handler
  end
end

describe Keen::Modeling::Extractors::Proc, '#extract_value' do
  it "uses the body of the proc as it's extracted value" do
    expect(proc_factory.extract_value).to eq 'test'
  end

  it 'has @value within scope on extract' do
    value = double(:title => 'This')
    proc = proc_factory(Proc.new { "#{value.title} is a title" }, value)
    expect(proc.extract_value).to eq 'This is a title'
  end
end

def proc_factory(proc = Proc.new { 'test' }, value = nil)
  Keen::Modeling::Extractors::Proc.new value, nil, proc
end
