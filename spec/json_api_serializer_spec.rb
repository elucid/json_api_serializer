require 'spec_helper'

describe JsonApiSerializer do
  it 'has a version number' do
    expect(JsonApiSerializer::VERSION).not_to be nil
  end

  it 'has some models' do
    expect{ Author }.to_not raise_exception
    expect{ Post }.to_not raise_exception
  end
end
