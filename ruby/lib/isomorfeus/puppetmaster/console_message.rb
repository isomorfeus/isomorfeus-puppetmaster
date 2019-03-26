module Isomorfeus
  module Puppetmaster
    class ConsoleMessage
      def initialize(message_hash = {})
        @message_hash = message_hash ? message_hash : {}
      end

      def method_missing(name, *args)
        if %i[column_number level location line_number text].include?(name)
          @message_hash[name.to_s]
        elsif %i[location url].include?(name)
          @message_hash['location'] ? @message_hash['location']['url'] : ''
        else
          super(name, *args)
        end
      end
    end
  end
end