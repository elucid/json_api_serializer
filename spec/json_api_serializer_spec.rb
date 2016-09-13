require 'spec_helper'

describe JsonApiSerializer do
  it 'has a version number' do
    expect(JsonApiSerializer::VERSION).not_to be nil
  end

  it 'has some models' do
    expect{ Author }.to_not raise_exception
    expect{ Post }.to_not raise_exception
  end

  describe JsonApiSerializer::Model do
    context "resource identifier object default" do
      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      subject(:serializer) { JsonApiSerializer::Model.new(author) }

      let(:expected_payload) do
        {
          data: {
            type: "authors",
            id: author.id
          }
        }
      end

      it "generates a JSON-API-compliant payload that includes just the resource identifier object" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "no relationships" do
      class AuthorSerializer < JsonApiSerializer::Model
        attributes :id, :name, :email
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      subject(:serializer) { AuthorSerializer.new(author) }

      let(:expected_payload) do
        {
          data: {
            type: "authors",
            id: author.id,
            attributes: {
              name: author.name,
              email: author.email
            }
          }
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "virtual attributes" do
      class AuthorFigSerializer < JsonApiSerializer::Model
        attributes :id, :name, :email, :figs

        def figs
          "JUICY"
        end
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      subject(:serializer) { AuthorFigSerializer.new(author) }

      let(:expected_payload) do
        {
          data: {
            type: "authors",
            id: author.id,
            attributes: {
              name: author.name,
              figs: "JUICY",
              email: author.email
            }
          }
        }
      end

      it "generates a JSON-API-compliant payload with virtual attributes" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end
  end
end
