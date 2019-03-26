module Isomorfeus
  module Puppetmaster
    class Request
      def initialize(request_hash = {})
        @request_hash = request_hash ? request_hash : {}
      end

      def method_missing(name, *args)
        if %i[failure headers method post_data resource_type url].include?(name)
          @request_hash[name.to_s]
        else
          super(name, *args)
        end
      end
    end
  end
end