module Isomorfeus
  module Puppetmaster
    class Response
      attr_reader :request

      def initialize(response_hash = {})
        @response_hash = response_hash ? response_hash : {}
        @request = Isomorfeus::Puppetmaster::Request.new(@response_hash['request'])
      end

      def method_missing(name, *args)
        if %i[headers ok remote_address security_details status status_text text url].include?(name)
          @response_hash[name.to_s]
        elsif :ok? == name
          @response_hash['ok']
        else
          super(name, *args)
        end
      end

      def ok?
        @response_hash[:ok]
      end
    end
  end
end