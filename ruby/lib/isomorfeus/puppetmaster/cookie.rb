module Isomorfeus
  module Puppetmaster
    class Cookie
      def initialize(attributes)
        @attributes = attributes
      end

      def ==(other)
        return super unless other.is_a? String
        value == other
      end

      def domain
        @attributes['domain']
      end

      def expires
        Time.at @attributes['expires'] unless [nil, 0, -1].include? @attributes['expires']
      end

      def http_only?
        !!@attributes['httpOnly']
      end

      def name
        @attributes['name']
      end

      def value
        @attributes['value']
      end

      def path
        @attributes['path']
      end

      def secure?
        !!@attributes['secure']
      end

      def same_site
        @attributes['sameSite']
      end
    end
  end
end
