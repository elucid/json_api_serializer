require "json_api_serializer/version"

module JsonApiSerializer
  Relationship = Struct.new(:name, :type, :options)

  class Model
    attr_reader :object

    def self.attributes(*attrs)
      @attributes ||= []

      return @attributes if attrs.empty?

      attrs.each do |attr|
        next if [ :id, :type ].include?(attr)

        case attr
        when /_id$/
          resource_name = attr.to_s.sub(/_id$/, '').to_sym

          add_relationship Relationship.new(resource_name, :has_one, {})
        when /_ids$/
          resource_name = attr.to_s.sub(/_ids$/, '').pluralize.to_sym

          add_relationship Relationship.new(resource_name, :has_many, {})
        else
          @attributes << attr
        end
      end
    end

    def self.relationships
      @relationships || []
    end

    def self.has_one(resource_name, options={})
      add_relationship Relationship.new(resource_name, :has_one, options)
    end

    def self.has_many(resource_name, options={})
      add_relationship Relationship.new(resource_name, :has_many, options)
    end

    def initialize(object, options={})
      @object = object
    end

    def resource_identifier_object
      {
        id: object.id,
        type: resource_type,
      }
    end

    def resource_object
      resource_identifier_object.tap do |object|
        object[:attributes] = attributes unless attributes.empty?
        object[:relationships] = relationships unless relationships.empty?
      end
    end

    def as_json(*args)
      {
        data: resource_object
      }
    end

    def attributes
      @_attributes ||= self.class.attributes.inject({}) do |attrs, a|
        attrs[a] = self.respond_to?(a) ? self.send(a) : object.send(a)
        attrs
      end
    end

    def relationships
      @_relationships ||= self.class.relationships.inject({}) do |rels, rel|
        if rel.options[:include]
          # TODO: add corresponding payload to the included data
        end

        case rel.type
        when :has_one
          rel_fk = "#{rel.name}_id"
          rel_id = object.send(rel_fk)
          rel_type = rel.name.to_s.pluralize
          rel_resource_identifier_object = { id: rel_id, type: rel_type }

          rels[rel.name] = { data: rel_resource_identifier_object }
        when :has_many
          rel_fk = "#{rel.name.to_s.singularize}_ids"
          rel_ids = object.send(rel_fk)
          rel_type = rel.name.to_s.pluralize
          rel_resource_identifier_objects = rel_ids.map do |rel_id|
            { id: rel_id, type: rel_type }
          end

          rels[rel.name] = { data: rel_resource_identifier_objects }
        end

        rels
      end
    end

    private

    def resource_type
      object.class.name.downcase.pluralize
    end

    def self.add_relationship(relationship)
      @relationships ||= []

      @relationships << relationship
    end
  end
end
