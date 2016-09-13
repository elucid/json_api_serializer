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

    context "has_one relationships" do
      class PostSerializerWithAuthor < JsonApiSerializer::Model
        attributes :title, :body

        has_one :author
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      let(:post) { Post.create!(title: 'post title', body: 'post body', author: author) }

      subject(:serializer) { PostSerializerWithAuthor.new(post) }

      let(:expected_payload) do
        {
          data: {
            type: "posts",
            id: post.id,
            attributes: {
              title: post.title,
              body: post.body
            },
            relationships: {
              author: {
                data: { id: author.id, type: "authors" }
              }
            }
          }
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "short-form has_one relationships" do
      class PostSerializerWithShortAuthor < JsonApiSerializer::Model
        attributes :title, :body, :author_id
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      let(:post) { Post.create!(title: 'post title', body: 'post body', author: author) }

      subject(:serializer) { PostSerializerWithShortAuthor.new(post) }

      let(:expected_payload) do
        {
          data: {
            type: "posts",
            id: post.id,
            attributes: {
              title: post.title,
              body: post.body
            },
            relationships: {
              author: {
                data: { id: author.id, type: "authors" }
              }
            }
          }
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "has_many relationships" do
      class AuthorSerializerWithPosts < JsonApiSerializer::Model
        attributes :name, :email

        has_many :posts
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      let!(:post1) { Post.create!(title: 'post1 title', body: 'post1 body', author: author) }
      let!(:post2) { Post.create!(title: 'post2 title', body: 'post2 body', author: author) }

      subject(:serializer) { AuthorSerializerWithPosts.new(author) }

      let(:expected_payload) do
        {
          data: {
            type: "authors",
            id: author.id,
            attributes: {
              name: author.name,
              email: author.email
            },
            relationships: {
              posts: {
                data: [
                  { id: post1.id, type: "posts" },
                  { id: post2.id, type: "posts" }
                ]
              }
            }
          }
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "short-form has_many relationships" do
      class AuthorSerializerWithShortPosts < JsonApiSerializer::Model
        attributes :name, :email, :post_ids
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      let!(:post1) { Post.create!(title: 'post1 title', body: 'post1 body', author: author) }
      let!(:post2) { Post.create!(title: 'post2 title', body: 'post2 body', author: author) }

      subject(:serializer) { AuthorSerializerWithShortPosts.new(author) }

      let(:expected_payload) do
        {
          data: {
            type: "authors",
            id: author.id,
            attributes: {
              name: author.name,
              email: author.email
            },
            relationships: {
              posts: {
                data: [
                  { id: post1.id, type: "posts" },
                  { id: post2.id, type: "posts" }
                ]
              }
            }
          }
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "included relationships"
  end
end
