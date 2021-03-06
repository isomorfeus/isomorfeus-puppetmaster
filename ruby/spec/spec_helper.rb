# frozen_string_literal: true

PUPPETMASTER_ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.join(PUPPETMASTER_ROOT, 'lib'))
ENV['NODE_PATH'] = File.join(PUPPETMASTER_ROOT, 'node_modules')

require 'bundler/setup'
require 'rspec'
require 'rspec/expectations'
require 'isomorfeus-puppetmaster'
require 'support/spec_logger'
require 'support/output_writer'
require 'nokogiri'
require 'test_app'
require 'shared/find_all'
require 'shared/drivers'
require 'shared/document'
require 'shared/evaluate_script'
require 'shared/html'

Isomorfeus::Puppetmaster.download_path = File.join(Dir.pwd, 'download_path_tmp')
js = Opal::Builder.new.build_str("require 'opal'\nrequire 'opal-browser'", 'puppetmaster_opal_prelude').to_s
File.write(File.join(__dir__, 'public', 'opal-with-browser.js'), js)

module Isomorfeus
  module Puppetmaster
    module SpecHelper
      class << self
        def configure(config)
          config.before { Isomorfeus::Puppetmaster::SpecHelper.reset! }
          config.after { Isomorfeus::Puppetmaster::SpecHelper.reset! }
        end

        def reset!
          Isomorfeus::Puppetmaster.app = TestApp
          Isomorfeus::Puppetmaster.host = nil
        end

        def spec(name, *options, &block)
          @specs ||= []
          @specs << [name, options, block]
        end

        def run_specs(session, name, **options, &filter_block)
          specs = @specs
          RSpec.describe Isomorfeus::Puppetmaster, name, options do # rubocop:disable RSpec/EmptyExampleGroup
            include Isomorfeus::Puppetmaster::SpecHelper
            include Isomorfeus::Puppetmaster::RSpecMatchers
            # rubocop:disable RSpec/ScatteredSetup
            before do |example|
              @session = session
              instance_exec(example, &filter_block) if filter_block
            end

            after do
              session.reset_session!
            end

            # rubocop:enable RSpec/ScatteredSetup

            specs.each do |spec_name, spec_options, block|
              describe spec_name, *spec_options do # rubocop:disable RSpec/EmptyExampleGroup
                class_eval(&block)
              end
            end
          end
        end
      end

      def silence_stream(stream)
        old_stream = stream.dup
        stream.reopen(RbConfig::CONFIG['host_os'] =~ /rmswin|mingw/ ? 'NUL:' : '/dev/null')
        stream.sync = true
        yield
      ensure
        stream.reopen(old_stream)
      end

      def quietly
        silence_stream(STDOUT) do
          silence_stream(STDERR) do
            yield
          end
        end
      end

      def extract_results(session)
        expect(session).to have_xpath("//pre[@id='results']")
        YAML.load Nokogiri::HTML(session.body).xpath("//pre[@id='results']").first.inner_html.lstrip
      end

      def be_an_invalid_element_error(session)
        satisfy { |error| session.driver.invalid_element_errors.any? { |e| error.is_a? e } }
      end
    end
  end
end


module TestSessions
  def self.logger
    @logger ||= SpecLogger.new
  end
end

RSpec.configure do |config|
  config.before do
    TestSessions.logger.reset
  end

  config.include Isomorfeus::Puppetmaster::DSL

  config.after do |example|
    puts TestSessions.logger.messages
  end
end

Dir[File.dirname(__FILE__) + '/session/**/*.rb'].each { |file| require_relative file }
