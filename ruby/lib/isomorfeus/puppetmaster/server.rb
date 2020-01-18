module Isomorfeus
  module Puppetmaster
    class Server
      class Timer
        def initialize(expire_in:)
          @start = current
          @expire_in = expire_in
        end

        def expired?
          raise Isomorfeus::Puppetmaster::FrozenInTime, 'Time appears to be frozen. Puppetmaster does not work with libraries which freeze time, consider using time travelling instead' if stalled?

          current - @start >= @expire_in
        end

        def stalled?
          @start == current
        end

        private

        if defined?(Process::CLOCK_MONOTONIC)
          def current; Process.clock_gettime Process::CLOCK_MONOTONIC; end
        else
          def current; Time.now.to_f; end
        end
      end

      class << self
        def ports
          @ports ||= {}
        end
      end

      attr_reader :app, :port, :host

      def initialize(app,
                     port: Isomorfeus::Puppetmaster.server_port,
                     host: Isomorfeus::Puppetmaster.server_host,
                     extra_middleware: [])
        @app = app
        @extra_middleware = extra_middleware
        @request_key = Isomorfeus::Puppetmaster::Server::ExecutorMiddleware.class_variable_get(:@@request_key)
        unless @request_key
          @request_key = SecureRandom.alphanumeric(128)
          Isomorfeus::Puppetmaster::Server::ExecutorMiddleware.class_variable_set(:@@request_key, @request_key)
        end
        @extra_middleware << Isomorfeus::Puppetmaster::Server::ExecutorMiddleware
        @server_thread = nil # suppress warnings
        @host = host
        @port = port
        @port ||= Isomorfeus::Puppetmaster::Server.ports[port_key]
        @port ||= find_available_port(host)
        @checker = Isomorfeus::Puppetmaster::Server::Checker.new(@host, @port)
      end

      def reset_error!
        middleware.clear_error
      end

      def error
        middleware.error
      end

      def on_server(ruby_source = '', &block)
        ruby_source = Isomorfeus::Puppetmaster.block_source_code(&block) if block_given?
        request_hash = { 'key' => @request_key, 'code' => ruby_source }
        response = if using_ssl?
                     http = Net::HTTP.start(@host, @port, { use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE })
                     http.post('/__executor__', Oj.dump(request_hash, mode: :strict))
                   else
                     http = Net::HTTP.start(@host, @port)
                     http.post('/__executor__', Oj.dump(request_hash, mode: :strict))
                   end
        if response.code == '200'
          result_hash = Oj.load(response.body)
          if result_hash.has_key?('error')
            error = RuntimeError.new(result_hash['error'])
            error.set_backtrace(result_hash['backtrace'])
            raise error
          end
          result_hash['result']
        else
          raise 'A error occurred.'
        end
      end

      def using_ssl?
        @checker.ssl?
      end

      def scheme
        using_ssl? ? 'https' : 'http'
      end

      def responsive?
        return false if @server_thread&.join(0)

        res = @checker.request { |http| http.get('/__identify__') }

        return res.body == app.object_id.to_s if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPRedirection)
      rescue SystemCallError, Net::ReadTimeout, OpenSSL::SSL::SSLError
        false
      end

      def wait_for_pending_requests
        timer = Isomorfeus::Puppetmaster::Server::Timer.new(expire_in: 60)
        while pending_requests?
          raise 'Requests did not finish in 60 seconds' if timer.expired?

          sleep 0.01
        end
      end

      def boot
        unless responsive?
          Isomorfeus::Puppetmaster::Server.ports[port_key] = port

          @server_thread = Thread.new do
            Isomorfeus::Puppetmaster.server.call(middleware, port, host)
          end

          timer = Isomorfeus::Puppetmaster::Server::Timer.new(expire_in: 60)
          until responsive?
            raise 'Rack application timed out during boot' if timer.expired?

            @server_thread.join(0.1)
          end
        end

        self
      end

    private

      def middleware
        @middleware ||= ::Isomorfeus::Puppetmaster::Server::Middleware.new(app, @extra_middleware)
      end

      def port_key
        app.object_id
      end

      def pending_requests?
        middleware.pending_requests?
      end

      def find_available_port(host)
        server = TCPServer.new(host, 0)
        server.addr[1]
      ensure
        server&.close
      end
    end
  end
end

