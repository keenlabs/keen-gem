require 'spec_helper'

describe Keen::Modeling::Extractors::Abstract, '#valid?' do
  let(:blank) { Keen::Modeling::Extractors::Abstract.new(nil, nil, nil) }

  it 'fails with "#valid? not implemented"' do
    expect { blank.handler? }.to raise_error RuntimeError
  end

end

describe Keen::Modeling::Extractors::Abstract, '#extract_value' do
  let(:blank) { Keen::Modeling::Extractors::Abstract.new(nil, nil, nil) }

  it 'fails with #extract_value not implemented' do
    expect { blank.extract_value }.to raise_error RuntimeError
  end
end

describe Keen::Modeling::Extractors::Abstract, '#extract' do
  let(:blank) { Keen::Modeling::Extractors::Abstract.new(nil, nil, nil) }

  it 'receives #extract_value when valid? is true' do
    allow(blank).to receive(:handler?) { true }
    expect(blank).to receive(:extract_value)

    blank.extract
  end

  it '@next receives #extract when valid? is false' do
    link = double
    blank.next = link

    allow(blank).to receive(:handler?) { false }
    expect(link).to receive(:extract)

    blank.extract
  end
end
