module Signatory
  module API
    class Base < ActiveResource::Base
      self.site = 'https://rightsignature.com/api/'
      self.format = ActiveResource::Formats::XmlFormat

      def id
        guid
      end

      def self.headers
        {'Content-Type'=>'text/xml'}
      end

      def self.find(guid)
        record = self.format.decode(Signatory.credentials.token.get("#{self.site}#{self.collection_name}/#{guid}.#{self.format.extension}",self.headers).body)

        self.send(:instantiate_record, record)
      end

      def post(method_name, options = {}, body = nil)
        content_type = body.blank? ? "application/x-www-form-urlencoded" : "text/xml"

        debugger

        if new?
          uri = custom_method_new_element_url(method_name, options)
        else
          uri = custom_method_element_url(method_name, options)
        end

        Signatory.credentials.token.post(uri,body,{'Content-Type'=>content_type})
      end

      def get(method_name, options = {})
        self.class.format.decode(Signatory.credentials.token.get(custom_method_element_url(method_name,self.class.headers)).body)
      end

      class << self
        def escape_url_attrs(*attrs)
          attrs.each do |attr|
            define_method attr do
              if Signatory.credentials.api_version == '1.0' || attributes[attr].blank?
                attributes[attr]
              else
                CGI::unescape(attributes[attr])
              end
            end
          end
        end

        def has_many(sym)
          self.write_inheritable_attribute(:__has_many, (read_inheritable_attribute(:__has_many)||[])+[sym])
        end

        def instantiate_record(record, opts={})
          (self.read_inheritable_attribute(:__has_many)||[]).each do |sym|
            record[sym.to_s] = [record[sym.to_s].try(:[],sym.to_s.singularize)].flatten.compact unless record[sym.to_s].is_a?(Array)
          end

          super(record, opts)
        end

        def instantiate_collection(collection, opts)
          if collection.has_key?(formatted_collection_name)
            collection = collection[formatted_collection_name]
          end
          super([collection[formatted_name]].flatten, opts)
        end

        def formatted_name
          self.name.split('::').last.downcase
        end

        def formatted_collection_name
          self.name.split('::').last.downcase.pluralize
        end

        def connection(refresh = false)
          if defined?(@connection) || superclass == Object
            @connection = Signatory::API::Connection.new(site, format) if refresh || @connection.nil?
            @connection.proxy = proxy if proxy
            @connection.user = user if user
            @connection.password = password if password
            @connection.auth_type = auth_type if auth_type
            @connection.timeout = timeout if timeout
            @connection.ssl_options = ssl_options if ssl_options
            @connection.format = ActiveResource::Formats::XmlFormat
            @connection
          else
            superclass.connection
          end
        end
      end
    end
  end
end