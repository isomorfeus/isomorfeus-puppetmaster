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
            response = nil
            unless request.body.nil?
              request_hash = Oj.load(request.body.read, mode: :strict)
              if request_hash['key'] != @@request_key
                response = Rack::Response.new(Oj.dump({ 'error' => 'wrong key given, execution denied' }),
                                             401,
                                             'Content-Type' => 'application/json')
              else
                begin
                  result = TOPLEVEL_BINDING.eval('self').instance_eval(request_hash['code']) if request_hash['code']
                  response = Rack::Response.new(Oj.dump({ 'result' => result }),
                                                200,
                                                'Content-Type' => 'application/json')
                rescue Exception => e
                  response = Rack::Response.new(Oj.dump({ 'error' => "#{e.class}: #{e.message}", 'backtrace' => e.backtrace.join("\n") }),
                                                200,
                                                'Content-Type' => 'application/json')
                end
              end
            end
            response.finish
          else
            @app.call(env)
          end
        end
      end
    end
  end
end
