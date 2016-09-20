require "json_api_serializer/version"

module JsonApiSerializer
  class DataSet < Set
  end

  class IncludedSet < Set
  end

  class ResourceObjectCache < Hash
  end

  Relationship = Struct.new(:name, :type, :options)

  class Base
    attr_reader :object, :options, :_jas_data_set, :_jas_included_set, :_jas_resource_object_cache

    def initialize(object, options={})
      @object = object
      @options = options
      @_jas_data_set = options[:_jas_data_set] ||= DataSet.new
      @_jas_included_set = options[:_jas_included_set] ||= IncludedSet.new
      @_jas_resource_object_cache = options[:_jas_resource_object_cache] ||= ResourceObjectCache.new
    end

    def scope
      options[:scope]
    end

    def included
      (_jas_included_set - _jas_data_set).map do |key|
        _jas_resource_object_cache[key]
      end
    end

    def as_json(*args)
      { data: data }.tap do |object|
        object[:included] = included unless included.empty?
      end
    end

    def serializer_for(factory)
      self.class.serializer_for(factory)
    end

    def self.serializer_for(factory)
      @_serializer_cache ||= {}
      @_serializer_cache[factory] ||=
        begin
          serializer =
            if "".respond_to?(:safe_constantize)
              "#{factory.name}Serializer".safe_constantize
            else
              begin
                "#{factory.name}Serializer".constantize
              rescue NameError => e
                raise unless e.message =~ /uninitialized constant/
              end
            end

          serializer || JsonApiSerializer::Model
        end
    end

    def has_many_fk(name)
      self.class.has_many_fk(name)
    end

    def self.has_many_fk(name)
      @_has_many_fk_cache ||= {}
      @_has_many_fk_cache[name] ||= "#{name.to_s.singularize}_ids"
    end

    def type_for_name(name)
      self.class.type_for_name(name)
    end

    def self.type_for_name(name)
      @_type_name_cache ||= {}
      @_type_name_cache[name] ||= name.to_s.downcase.pluralize
    end
  end

  class Collection < Base
    def data
      object.map do |model|
        key = [ model.id, model.class ]
        _jas_data_set.add(key)
        _jas_resource_object_cache[key] ||= serializer_for(model.class).new(model, options).data
      end
    end
  end

  class Model < Base
    def self.define_include_method(name)
      method = "include_#{name}?".to_sym

      unless method_defined?(method)
        define_method method do
          true
        end
      end
    end

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
          unless method_defined?(attr)
            define_method attr do
              object.send(attr)
            end
          end

          define_include_method(attr)

          @attributes << attr
        end
      end

      # NOTE: technique stolen from AMS 0.8
      # protect inheritance chains and open classes
      # if a serializer inherits from another OR
      #  attributes are added later in a classes lifecycle
      # poison the cache
      define_method :_fast_attributes do
        raise NameError
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

    def data
      key = [ object.id, object.class ]
      _jas_data_set.add(key)
      _jas_resource_object_cache[key] ||= resource_object
    end

    # NOTE: technique stolen from AMS 0.8
    def attributes
      _fast_attributes

      rescue NameError

      method = "def _fast_attributes\n"
      method << "  @_attributes ||=\n"
      method << "    begin\n"
      method << "      h = {}\n"

      self.class.attributes.each do |name|
        method << "      h[:\"#{name}\"] = send(:\"#{name}\") if include_#{name}?\n"
      end

      method << "      h\n"
      method << "    end\n"
      method << "end"

      self.class.class_eval method

      _fast_attributes
    end

    def relationships
      @_relationships ||= self.class.relationships.inject({}) do |rels, rel|
        case [ rel.type, !!rel.options[:include] ]
        when [ :has_one, false ]
          rel_fk = "#{rel.name}_id"
          rel_id = object.respond_to?(rel_fk) ? object.send(rel_fk) : object.send(rel.name).id
          rel_type = type_for_name(rel.name)
          rel_resource_identifier_object = { id: rel_id, type: rel_type }

          rels[rel.name] = { data: rel_resource_identifier_object }
        when [ :has_one, true ]
          rel_type = type_for_name(rel.name)
          rel_object = object.send(rel.name)
          rel_id = rel_object.id
          rel_class = rel_object.class
          rel_type = type_for_name(rel.name)
          rel_resource_identifier_object = { id: rel_id, type: rel_type }
          rels[rel.name] = { data: rel_resource_identifier_object }

          key = [ rel_id, rel_class ]

          unless _jas_included_set.include?(key) || _jas_data_set.include?(key)
            _jas_included_set.add(key)
            rel_serializer = serializer_for(rel_class).new(rel_object, options)
            _jas_resource_object_cache[key] ||= rel_serializer.resource_object
          end
        when [ :has_many, false ]
          rel_fk = has_many_fk(rel.name)
          association_loaded =
            begin
              object.association(rel.name).loaded?
            rescue ActiveRecord::AssociationNotFoundError
            end

          rel_ids =
            case
            when association_loaded # avoids forcing extra query if association loaded
              object.send(rel.name).map(&:id)
            when object.respond_to?(rel_fk) # avoids loading association if not loaded
              object.send(rel_fk)
            else # just have to suck it up and load the association
              object.send(rel.name).map(&:id)
            end

          rel_type = type_for_name(rel.name)
          rel_resource_identifier_objects = rel_ids.map do |rel_id|
            { id: rel_id, type: rel_type }
          end

          rels[rel.name] = { data: rel_resource_identifier_objects }
        when [ :has_many, true ]
          rel_objects = object.send(rel.name)

          rel_resource_identifier_objects = rel_objects.map do |rel_object|
            rel_id = rel_object.id
            rel_class = rel_object.class
            rel_type = type_for_name(rel_class.name)

            key = [ rel_id, rel_class ]

            unless _jas_included_set.include?(key) || _jas_data_set.include?(key)
              _jas_included_set.add(key)
              rel_serializer = serializer_for(rel_class).new(rel_object, options)
              _jas_resource_object_cache[key] ||= rel_serializer.resource_object
            end

            { id: rel_id, type: rel_type }
          end

          rels[rel.name] = { data: rel_resource_identifier_objects }
        end

        rels
      end
    end

    private

    def resource_type
      type_for_name(object.class.name)
    end

    def self.add_relationship(relationship)
      @relationships ||= []

      @relationships << relationship
    end
  end
end
