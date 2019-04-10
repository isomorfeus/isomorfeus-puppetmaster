# frozen_string_literal: true

require 'spec_helper'
require 'pdf/reader'
require 'chunky_png'
require 'fastimage'
require 'os'

module DriverSpec
  describe 'firefox' do
    before :all do
      warn "\nDriver: puppeteer firefox\n"
      Isomorfeus::Puppetmaster.app = TestApp
      Isomorfeus::Puppetmaster.boot_app
      Isomorfeus::Puppetmaster.driver = :firefox
      reset_session!
    end

    it 'show generic browser information' do
      doc = visit('/')
      expect(doc.browser).to include('Mozilla/')
      expect(doc.browser).to include('Firefox/')
    end

    it_behaves_like 'document and node'
    it_behaves_like 'document and node enhanced'
    it_behaves_like '#evaluate_script'
    it_behaves_like '#find'
    it_behaves_like '#find enhanced'
    it_behaves_like '#find_all'
    it_behaves_like 'html'
    it_behaves_like 'html enhanced'
    # it_behaves_like 'console'
    it_behaves_like 'scrolling'
    it_behaves_like 'viewport'
    # it_behaves_like 'save_pdf'
    it_behaves_like 'render_base64'
    it_behaves_like 'save_screenshot'
    it_behaves_like 'headers'
    # it_behaves_like 'cookies'
    # it_behaves_like 'cookies enhanced'
    # it_behaves_like 'basic http authentication'
    # it_behaves_like 'blacklisting urls for resource requests'
    it_behaves_like 'javascript'
    it_behaves_like 'javascript load errors'
    it_behaves_like 'mouse'
    it_behaves_like 'type keys'
    it_behaves_like 'type keys enhanced'
    it_behaves_like 'set content editable value'
    it_behaves_like 'date fields'
    it_behaves_like 'date fields enhanced'
    it_behaves_like 'errors and status codes'

    it 'url_blacklists can be configured in the driver' do
      skip 'doesnt seem to work'
      Isomorfeus::Puppetmaster.register_driver :firefox_blacklist do |app|
        Isomorfeus::Puppetmaster::Driver::Puppeteer.new(browser_type: :firefox, headless: true, app: app, url_blacklist: ['unwanted'])
      end

      session = new_session(Isomorfeus::Puppetmaster.served_app, :firefox_blacklist)

      doc = session.default_document
      doc.visit '/puppetmaster/url_blacklist'
      expect(doc).to have_text('We are loading some unwanted action here')
      frame = doc.find_by_name('framename')
      expect(frame.html).not_to include('We shouldn\'t see this.')
    end

    it 'HTTPS errors can be ignored by default' do
      skip 'todo'
      # Isomorfeus::Puppetmaster::JavaScriptError:
      # [JavaScript Error: "The character encoding of the HTML document was not declared. The document will render with garbled
      # text in some browser configurations if the document contains characters from outside the US-ASCII range.
      # The character encoding of the page must be declared in the document or in the transfer protocol."
      # {file: "https://expired.badssl.com/" line: 0}]
      # maybe a node 10.15.3 issue vs node 11
      Isomorfeus::Puppetmaster.register_driver :firefox_allow_ssl do |app|
        Isomorfeus::Puppetmaster::Driver::Puppeteer.new(browser_type: :firefox, headless: true, app: app, ignore_https_errors: true)
      end
      session = open_new_session(Isomorfeus::Puppetmaster.served_app, :firefox_allow_ssl)
      doc = session.default_document
      doc.visit('https://expired.badssl.com')
      expect(doc).to have_css('#content', text: "expired.\nbadssl.com")
    end

    it 'viewport allows for custom maximization size' do
      Isomorfeus::Puppetmaster.register_driver :firefox_with_custom_max_size do |app|
        Isomorfeus::Puppetmaster::Driver::Puppeteer.new(browser_type: :firefox, headless: true, app: app, max_width: 800, max_height: 600)
      end
      session = open_new_session(Isomorfeus::Puppetmaster.served_app, :firefox_with_custom_max_size)
      doc = session.default_document
      doc.visit('/')
      doc.viewport_resize(400, 400)
      doc.viewport_maximize
      expect(doc.viewport_size).to eq([800, 600])
      reset_session!
    end
  end

  # describe 'firefox_debug' do
  #   before :all do
  #     Isomorfeus::Puppetmaster.app = TestApp
  #     Isomorfeus::Puppetmaster.boot_app
  #     Isomorfeus::Puppetmaster.driver = :firefox_debug
  #     reset_session!
  #   end
  #
  #   it 'show generic browser information' do
  #     doc = visit('/')
  #     expect(doc.browser).to include('Mozilla/')
  #     expect(doc.browser).to include('Firefox/')
  #   end
  #
  #   # it_behaves_like 'console'
  #   it_behaves_like 'scrolling'
  #   it_behaves_like 'viewport'
  #   it_behaves_like 'render_base64'
  #   it_behaves_like 'save_screenshot'
  #   it_behaves_like 'headers'
  #   # it_behaves_like 'cookies'
  #   # it_behaves_like 'basic http authentication'
  #   it_behaves_like 'blacklisting urls for resource requests'
  #   it_behaves_like 'javascript'
  #   it_behaves_like 'mouse'
  #   it_behaves_like 'type keys'
  #   it_behaves_like 'type keys enhanced'
  #   it_behaves_like 'set content editable value'
  #   it_behaves_like 'date fields'
  #   it_behaves_like 'errors and status codes'
  #
  #   it 'url_blacklists can be configured in the driver' do
  #     skip 'doesnt seem to work'
  #     Isomorfeus::Puppetmaster.register_driver :firefox_blacklist do |app|
  #       Isomorfeus::Puppetmaster::Puppeteer.new(browser_type: :firefox, headless: false, devtools: true, app: app, url_blacklist: ['unwanted'])
  #     end
  #
  #     session = new_session(Isomorfeus::Puppetmaster.served_app, :firefox_blacklist)
  #
  #     doc = session.default_document
  #     doc.visit '/puppetmaster/url_blacklist'
  #     expect(doc).to have_text('We are loading some unwanted action here')
  #     frame = doc.find_by_name('framename')
  #     expect(frame.html).not_to include('We shouldn\'t see this.')
  #   end
  #
  #   it 'HTTPS errors can be ignored by default' do
  #     Isomorfeus::Puppetmaster.register_driver :firefox_allow_ssl do |app|
  #       Isomorfeus::Puppetmaster::Puppeteer.new(browser_type: :firefox, headless: false, devtools: true, app: app, ignore_https_errors: true)
  #     end
  #     session = new_session(Isomorfeus::Puppetmaster.served_app, :firefox_allow_ssl)
  #     doc = session.default_document
  #     doc.visit('https://expired.badssl.com')
  #     expect(doc).to have_css('#content', text: "expired.\nbadssl.com")
  #   end
  #
  #   it 'viewport allows for custom maximization size' do
  #     Isomorfeus::Puppetmaster.register_driver :firefox_with_custom_max_size do |app|
  #       Isomorfeus::Puppetmaster::Puppeteer.new(browser_type: :firefox, headless: false, devtools: true, app: app, max_width: 800, max_height: 600)
  #     end
  #     session = new_session(Isomorfeus::Puppetmaster.served_app, :firefox_with_custom_max_size)
  #     doc = session.default_document
  #     doc.visit('/')
  #     doc.viewport_resize(400, 400)
  #     doc.viewport_maximize
  #     expect(doc.viewport_size).to eq([800, 600])
  #     reset_session!
  #   end
  # end
end
