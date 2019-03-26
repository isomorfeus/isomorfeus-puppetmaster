# frozen_string_literal: true

# Boots a single Capybara::Server for a Rack application that delegates to another, singleton Rack
# application that can be configured for each spec.

require 'sinatra/base'

module AppRunner
  class << self
    attr_accessor :app, :app_host, :browser, :configuration
    attr_reader :server
  end

  def self.boot
    app_container = ->(env) { AppRunner.app.call(env) }
    @server = Isomorfeus::Puppetmaster::Server.new(app_container)
    @server.boot
    self.app_host = "http://127.0.0.1:#{server.port}"
  end

  def self.reset
    self.app = -> { [200, { 'Content-Type' => 'html', 'Content-Length' => 0 }, []] }
  end

  def run_application(app)
    AppRunner.app = app
  end

  def configure
    yield AppRunner.configuration
  end

  def driver_for_app(**options, &body)
    app = Class.new(ExampleApp, &body)
    run_application app
    AppRunner.build_driver(**options)
  end

  def driver_for_html(html, **driver_options)
    run_application_for_html html
    AppRunner.build_driver driver_options
  end

  def session_for_app(&body)
    app = Class.new(ExampleApp, &body)
    run_application app
    Isomorfeus::Puppetmaster.drivers[Isomorfeus::Puppetmaster.driver].call(AppRunner.app)
  end

  def run_application_for_html(html)
    run_application lambda { |_env|
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => html.size.to_s }, [html]]
    }
  end

  def self.build_driver(**opts)
    Isomorfeus::Puppeteer.new(browser_type: :chromium, headless: true)
  end

  def self.options
    configuration.to_hash
  end
  private_class_method :options

  def self.included(example_group)
    example_group.class_eval do
      before { AppRunner.reset }
      # after { $webkit_browser.reset! }
    end
  end
end

class ExampleApp < Sinatra::Base
  # Sinatra fixes invalid responses that would break QWebPage, so this middleware breaks them again
  # for testing purposes.
  class ResponseInvalidator
    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)
      if response.to_a[1]['X-Response-Invalid']
        [404, {}, []]
      else
        response
      end
    end
  end

  use ResponseInvalidator

  def invalid_response
    [200, { 'X-Response-Invalid' => 'TRUE' }, []]
  end
end

AppRunner.boot
