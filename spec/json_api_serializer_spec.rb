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

    context "include helpers" do
      class AuthorSerializerWithConditionalAttributes < JsonApiSerializer::Model
        attributes :id, :name, :email

        def include_name?
          false
        end
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      subject(:serializer) { AuthorSerializerWithConditionalAttributes.new(author) }

      let(:expected_payload) do
        {
          data: {
            type: "authors",
            id: author.id,
            attributes: {
              email: author.email
            }
          }
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "include helpers for relationships" do
      class AuthorSerializerWithConditionalPosts < JsonApiSerializer::Model
        attributes :id, :name, :email

        has_many :posts

        def include_posts?
          false
        end
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      subject(:serializer) { AuthorSerializerWithConditionalPosts.new(author) }

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

    context "scope" do
      class AuthorSerializerWithScopeConditionalAttributes < JsonApiSerializer::Model
        attributes :id, :name, :email

        def include_email?
          scope.admin?
        end
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      let(:current_user) { double(:user, admin?: false) }

      subject(:serializer) { AuthorSerializerWithScopeConditionalAttributes.new(author, scope: current_user) }

      let(:expected_payload) do
        {
          data: {
            type: "authors",
            id: author.id,
            attributes: {
              name: author.name
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

    context "included relationships" do
      context "has_one" do
        class PostSerializerWithAuthorIncluded < JsonApiSerializer::Model
          attributes :title, :body

          has_one :author, include: true
        end

        class AuthorSerializerForInclude < JsonApiSerializer::Model
          attributes :name, :email

          has_many :posts
        end

        let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

        let(:post) { Post.create!(title: 'post title', body: 'post body', author: author) }

        subject(:serializer) { PostSerializerWithAuthorIncluded.new(post) }

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
            },
            included: [
              {
                type: "authors",
                id: author.id,
                attributes: {
                  name: author.name,
                  email: author.email
                },
                relationships: {
                  posts: {
                    data: [
                      { id: post.id, type: "posts" }
                    ]
                  }
                }
              }
            ]
          }
        end

        it "generates a JSON-API-compliant payload" do
          expect(PostSerializerWithAuthorIncluded).to receive(:serializer_for).with(Author).and_return(AuthorSerializerForInclude).once
          expect(serializer.as_json).to eq(expected_payload)
        end
      end
    end
  end

  describe JsonApiSerializer::Collection do
    context "simple collection" do
      class PostSerializerSimple < JsonApiSerializer::Model
        attributes :id, :title, :body
      end

      let!(:post1) { Post.create!(title: 'post1 title', body: 'post1 body') }
      let!(:post2) { Post.create!(title: 'post2 title', body: 'post2 body') }

      subject(:serializer) { JsonApiSerializer::Collection.new([ post1, post2 ]) }

      let(:expected_payload) do
        {
          data: [
            {
              type: "posts",
              id: post1.id,
              attributes: {
                title: post1.title,
                body: post1.body
              },
            },
            {
              type: "posts",
              id: post2.id,
              attributes: {
                title: post2.title,
                body: post2.body
              },
            }
          ]
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(JsonApiSerializer::Collection).to receive(:serializer_for).with(Post).and_return(PostSerializerSimple).twice
        expect(serializer.as_json).to eq(expected_payload)
      end
    end

    context "collection with relationships and includes" do
      class PostSerializerWithRelsAndIncludes < JsonApiSerializer::Model
        attributes :id, :title, :body

        has_one :author, include: true
      end

      class AuthorSerializerWithRelsAndIncludes < JsonApiSerializer::Model
        attributes :name, :email

        has_many :posts, include: true
      end

      let(:author) { Author.create!(name: 'fred', email: 'fred@flintstone.org') }

      let!(:post1) { Post.create!(title: 'post1 title', body: 'post1 body', author: author) }
      let!(:post2) { Post.create!(title: 'post2 title', body: 'post2 body', author: author) }

      subject(:serializer) { JsonApiSerializer::Collection.new([ post1, post2 ]) }

      let(:expected_payload) do
        {
          data: [
            {
              type: "posts",
              id: post1.id,
              attributes: {
                title: post1.title,
                body: post1.body
              },
              relationships: {
                author: {
                  data: { id: author.id, type: "authors" }
                }
              }
            },
            {
              type: "posts",
              id: post2.id,
              attributes: {
                title: post2.title,
                body: post2.body
              },
              relationships: {
                author: {
                  data: { id: author.id, type: "authors" }
                }
              }
            }
          ],
          included: [
            {
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
          ]
        }
      end

      it "generates a JSON-API-compliant payload" do
        expect(JsonApiSerializer::Base).to receive(:serializer_for).with(Post).and_return(PostSerializerWithRelsAndIncludes).twice
        expect(JsonApiSerializer::Base).to receive(:serializer_for).with(Author).and_return(AuthorSerializerWithRelsAndIncludes).once
        expect(serializer.as_json).to eq(expected_payload)
      end
    end
  end
end
