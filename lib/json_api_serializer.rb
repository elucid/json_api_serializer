require "json_api_serializer/version"

module JsonApiSerializer
  class Model
    attr_reader :object

    def self.attributes(*attrs)
      @attributes ||= []

      return @attributes if attrs.empty?

      attrs.each do |attr|
        next if [ :id, :type ].include?(attr)

        @attributes << attr
      end
    end

    def initialize(object, options={})
      @object = object
    end

    def resource_object
      resource_identifier_object.tap do |object|
        object[:attributes] = attributes unless attributes.empty?
      end
    end

    def attributes
      @_attributes ||= self.class.attributes.inject({}) do |attrs, a|
        attrs[a] = self.respond_to?(a) ? self.send(a) : object.send(a)
        attrs
      end
    end

    def resource_identifier_object
      {
        id: object.id,
        type: resource_type,
      }
    end

    def as_json(*args)
      {
        data: resource_object
      }
    end

    private

    def resource_type
      object.class.name.downcase.pluralize
    end
  end
end
