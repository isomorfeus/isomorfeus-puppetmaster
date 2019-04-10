# frozen_string_literal: true

module Isomorfeus
  module Puppetmaster
    class Server
      class ExecutorMiddleware
        @@request_key = nil

        def initialize(app)
          raise '@@request_key not set!' unless @@request_key
          @app = app
        end

        def call(env)
          if env['PATH_INFO'] == '/__executor__' && env['REQUEST_METHOD'] == 'POST'
            request = Rack::Request.new(env)
            unless request.body.nil?
              request_hash = Oj.load(request.body.read, {})
              if request_hash['key'] != @@request_key
                Rack::Response.new(Oj.dump({ 'error' => 'wrong key given, execution denied' }, {}), 401, 'Content-Type' => 'application/json').finish
              end
              begin
                result = Object.instance_eval(request_hash['code']) if request_hash['code']
              rescue Exception => e
                Rack::Response.new(Oj.dump({ 'error' => "#{e.class}: #{e.message}" }, {}), 200, 'Content-Type' => 'application/json').finish
              end
              Rack::Response.new(Oj.dump({ 'result' => result }, {}), 200, 'Content-Type' => 'application/json').finish
            end
          else
            @app.call(env)
          end
        end
      end
    end
  end
end
