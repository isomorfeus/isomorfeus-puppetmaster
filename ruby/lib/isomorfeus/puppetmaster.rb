module Isomorfeus
  module Puppetmaster
    class << self
      attr_accessor :app, :server_port, :session
      attr_writer :download_path, :server_host, :server_scheme
      attr_reader :served_app, :server

      def boot_app
        @served_app = Isomorfeus::Puppetmaster::Server.new(app, port: server_port, host: server_host).boot
      end

      def block_source_code(&block)
        source_block = Parser::CurrentRuby.parse(block.source).children.last
        source_block = source_block.children.last if source_block.type == :block
        Unparser.unparse(source_block)
      end

      def driver
        @driver ||= :chromium
      end

      def driver=(drvr)
        raise "#{drvr}: no such driver registered! Available drivers: #{drivers.keys.join(', ')}." unless drivers.has_key?(drvr)
        @driver = drvr
      end

      def drivers
        @drivers ||= {}
      end

      def opal_prelude
        @opal_prelude ||= build_opal_prelude
      end

      def register_driver(name, &block)
        drivers[name.to_sym] = block
      end

      def register_server(name, &block)
        servers[name.to_sym] = block
      end

      def download_path
        @download_path ||= Dir.pwd
      end

      def server=(name)
        raise "#{name}: no such server registered! Available drivers: #{servers.keys.join(', ')}." unless servers.has_key?(name)
        name, options = *name if name.is_a? Array
        @server = if name.respond_to? :call
                    name
                  elsif options
                    proc { |app, port, host| servers[name.to_sym].call(app, port, host, options) }
                  else
                    servers[name.to_sym]
                  end
      end

      def server_host
        @server_host ||= '127.0.0.1'
      end

      def server_scheme
        @server_scheme ||= 'http'
      end

      def servers
        @servers ||= {}
      end

      private

      def build_opal_prelude
        js = Opal::Builder.new.build_str("require 'opal'\nrequire 'opal-browser'", 'puppetmaster_opal_prelude').to_s
      end
    end
  end
end
