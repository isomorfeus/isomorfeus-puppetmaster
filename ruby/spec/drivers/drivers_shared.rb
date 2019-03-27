module DriverSpec
  shared_examples 'basic http authentication' do
    before do
      @doc = visit('/')
    end

    after do
      # reset auth after each test
      @doc.clear_authentication_credentials
      @doc.clear_extra_headers
    end

    it 'denies without credentials' do
      skip 'prompts and waits forever' if %i[chromium chromium_debug].include?(Isomorfeus::Puppetmaster.driver)
      @doc.clear_authentication_credentials
      @doc.visit '/puppetmaster/basic_auth'

      expect(@doc.response.status).to eq(401)
      expect(@doc).not_to have_text('Welcome, authenticated client')
    end

    it 'denies with wrong credentials' do
      @doc.set_authentication_credentials('user', 'pass!')

      @doc.visit '/puppetmaster/basic_auth'

      expect(@doc.response.status).to eq(401)
      expect(@doc).not_to have_text('Welcome, authenticated client')
    end

    it 'allows with given credentials' do
      @doc.set_authentication_credentials('login', 'pass')

      @doc.visit '/puppetmaster/basic_auth'

      expect(@doc.response.status).to eq(200)
      expect(@doc).to have_text('Welcome, authenticated client')
    end

    it 'allows even overwriting headers' do
      @doc.set_authentication_credentials('login', 'pass')
      @doc.set_extra_headers({ 'Puppetmaster' => 'true' })
      @doc.visit '/puppetmaster/basic_auth'

      expect(@doc.response.status).to eq(200)
      expect(@doc).to have_text('Welcome, authenticated client')
    end

    it 'allows on POST request' do
      @doc.set_authentication_credentials('login', 'pass')

      @doc.visit '/puppetmaster/basic_auth'
      expect(@doc.response.status).to eq(200)
      @doc.find_by_value('Submit').click

      expect(@doc.response.status).to eq(200)
      expect(@doc).to have_text('Authorized POST request')
    end
  end

  shared_examples 'blacklisting urls for resource requests' do
    before do
      @doc = visit '/'
    end

    after do
      @doc.clear_url_blacklist
    end

    it 'a new window inherits url_blacklist' do
      @doc = visit('/')
      @doc.set_url_blacklist(['unwanted'])
      @new_doc = @doc.open_new_document('/puppetmaster/url_blacklist')
      expect(@new_doc).to have_text('We are loading some unwanted action here')
      frame = @new_doc.find_by_name 'framename'
      expect(frame.html).not_to include('We shouldn\'t see this.')
      @new_doc.close
    end

    it 'blocks unwanted urls' do
      @doc.set_url_blacklist(['unwanted'])
      @doc.visit '/puppetmaster/url_blacklist'

      expect(@doc.response.status).to eq(200)
      expect(@doc).to have_text('We are loading some unwanted action here')
      frame = @doc.find_by_name 'framename'
      expect(frame.html).not_to include('We shouldn\'t see this.')
    end

    it 'supports wildcards' do
      @doc.set_url_blacklist(['*wanted'])

      @doc.visit '/puppetmaster/url_whitelist'

      expect(@doc.response.status).to eq(200)
      expect(@doc).to have_text('We are loading some wanted action here')
      frame = @doc.find_by_name 'framename'
      expect(frame).not_to have_text('We should see this.')
      frame = @doc.find_by_name 'unwantedframe'
      expect(frame).not_to have_text("We shouldn't see this.")
    end
  end

  shared_examples 'console' do
    it 'can access the console' do
      doc = visit('/puppetmaster/console_log')
      expect(doc.console.first&.text).to include('Hello world')
    end
  end

  shared_examples 'cookies enhanced' do
    before do
      @doc = visit('/')
    end

    it 'can set cookies with custom settings' do
      @doc.set_cookie 'puppetmaster', 'wow', path: '/puppetmaster'

      @doc.visit('/get_cookie')
      expect(@doc.body.visible_text).not_to include('wow')

      @doc.visit('/puppetmaster/get_cookie')
      expect(@doc.body.visible_text).to include('wow')
      expect(@doc.cookies['puppetmaster'].path).to eq('/puppetmaster')
    end

    it 'can set cookies for given domain' do
      port = URI.parse(@doc.url).port
      @doc.set_cookie 'puppetmaster', '127.0.0.1'
      @doc.set_cookie 'puppetmaster', 'localhost', domain: 'localhost'

      @doc.visit("http://localhost:#{port}/puppetmaster/get_cookie")
      expect(@doc.body.visible_text).to include('localhost')

      @doc.visit("http://127.0.0.1:#{port}/puppetmaster/get_cookie")
      expect(@doc.body.visible_text).to include('127.0.0.1')
    end
  end

  shared_examples 'cookies' do
    before do
      @doc = visit('/')
    end

    it 'returns set cookies' do
      @doc.visit('/set_cookie')
      cookie = @doc.cookies['puppetmaster']
      expect(cookie.name).to eq('puppetmaster')
      expect(cookie.value).to eq('test_cookie')
      expect(cookie.domain).to eq('127.0.0.1')
      expect(cookie.path).to eq('/')
      expect(cookie.secure?).to be false
      expect(cookie.http_only?).to be false
      expect(cookie.same_site).to be_nil
      expect(cookie.expires).to be_nil
    end

    it 'can set cookies' do
      @doc.set_cookie 'puppetmaster', 'omg'
      @doc.visit('/get_cookie')
      expect(@doc.body.visible_text).to include('omg')
    end

    it 'can remove a cookie' do
      @doc.visit('/set_cookie')

      @doc.visit('/get_cookie')
      expect(@doc.body.visible_text).to include('test_cookie')

      @doc.remove_cookie 'puppetmaster'

      @doc.visit('/get_cookie')
      expect(@doc.body.visible_text).not_to include('test_cookie')
    end

    it 'can clear cookies' do
      @doc.visit('/set_cookie')

      @doc.visit('/get_cookie')
      expect(@doc.body.visible_text).to include('test_cookie')

      @doc.clear_cookies

      @doc.visit('/get_cookie')
      expect(@doc.body.visible_text).not_to include('test_cookie')
    end

    it 'can set cookies with an expires time' do
      time = Time.at(Time.now.to_i + 10_000)
      @doc.visit '/'
      @doc.set_cookie 'foo', 'bar', expires: time
      expect(@doc.cookies['foo'].expires).to eq(time)
    end
  end

  shared_examples 'errors and status codes' do
    context 'HTTPS Errors' do
      before do
        @doc = visit('/')
      end

      it "aren't ignored by default" do
        expect { @doc.visit('https://expired.badssl.com') }.to raise_error Isomorfeus::Puppetmaster::CertificateError
      end
    end

    context "DNS Errors" do
      before do
        @doc = visit('/')
        @port =URI.parse(@doc.url).port
      end

      it 'does not occur when DNS correct' do
        expect { @doc.visit("http://localhost:#{@port}/") }.not_to raise_error
      end

      it 'handles when DNS incorrect' do
        expect { @doc.visit("http://nope:#{@port}/") }.to raise_error(Isomorfeus::Puppetmaster::DNSError)
      end
    end

    context 'status code support' do
      before do
        @doc = visit('/')
      end
      it 'determines status from the simple response' do
        @doc.visit('/puppetmaster/status/500')
        expect(@doc.response.status).to eq(500)
      end

      it 'determines status code when the page has a few resources' do
        @doc.visit('/puppetmaster/with_different_resources')
        expect(@doc.response.status).to eq(200)
      end

      it 'determines status code even after redirect' do
        @doc.visit('/puppetmaster/redirect')
        expect(@doc.response.status).to eq(200)
      end
    end
  end

  shared_examples 'headers' do
    before do
      @doc = visit('/')
    end

    after do
      @doc.clear_extra_headers
    end

    it 'allows headers to be set' do
      @doc.set_extra_headers(
        'Xtra' => 'foo=bar',
        'Host' => 'foo.com'
      )
      @doc.visit('/puppetmaster/headers')
      expect(@doc.body.visible_text).to include('XTRA: foo=bar')
      expect(@doc.body.visible_text).to include('HOST: foo.com')
    end

    it 'setting User-Agent' do
      @doc.set_user_agent('foo')
      @doc.visit '/'
      expect(@doc.evaluate_script('window.navigator.userAgent')).to eq('foo')
    end

    it 'sets headers for all HTTP requests' do
      @doc.set_extra_headers( 'X-Omg' => 'wat' )
      @doc.visit '/'
      @doc.execute_script(<<~JS)
          var request = new XMLHttpRequest();
          request.open('GET', '/puppetmaster/headers', false);
          request.send();

          if (request.status === 200) {
            document.body.innerHTML = request.responseText;
          }
      JS
      expect(@doc.body.visible_text).to include('X_OMG: wat')
    end

    it 'sets headers on the initial request and keeps them for subsequent requests' do
      @doc.set_extra_headers( 'PermanentA' => 'a', 'PermanentB' => 'b',
                              'Referer' => 'http://google.com', 'TempA' => 'a' )

      @doc.visit('/puppetmaster/headers_with_ajax')
      initial_request = @doc.find('#initial_request').visible_text
      ajax_request = @doc.find('#ajax_request').visible_text

      expect(initial_request).to include('PERMANENTA: a')
      expect(initial_request).to include('PERMANENTB: b')
      expect(initial_request).to include('REFERER: http://google.com')
      expect(initial_request).to include('TEMPA: a')

      expect(ajax_request).to include('PERMANENTA: a')
      expect(ajax_request).to include('PERMANENTB: b')
      expect(ajax_request).to include('TEMPA: a')
      expect(ajax_request).to include('REFERER: http://google.com')
    end

    it 'keeps added headers on redirects by default' do
      @doc.set_extra_headers('X-Custom-Header' => '1')
      @doc.visit('/puppetmaster/redirect_to_headers')
      expect(@doc.body.visible_text).to include('X_CUSTOM_HEADER: 1')
    end

    it 'can clear headers' do
      @doc.set_extra_headers('X-Custom2-Header' => '1')

      @doc.visit('/puppetmaster/redirect_to_headers')
      initial_body = @doc.body.visible_text

      @doc.clear_extra_headers

      @doc.visit('/puppetmaster/redirect_to_headers')
      cleared_body = @doc.body.visible_text

      expect(initial_body).to include('X_CUSTOM2_HEADER: 1')
      expect(cleared_body).not_to include('X_CUSTOM2_HEADER: 1')
    end

    context 'multiple docs' do
      before do
        @orig_doc = @doc
      end

      after do
        @doc = @orig_doc
      end

      it 'does not persist headers across popup windows' do
        @doc.set_extra_headers(
          'Xtra' => 'foo=bar',
          'Host' => 'foo.com'
        )
        @doc.set_user_agent('foo')
        @doc.visit('/puppetmaster/popup_headers')
        new_doc = @doc.open_document_by do
          @doc.find_by_content('pop up').click
        end
        expect(new_doc.body.visible_text).not_to include('XTRA: foo=bar')
        expect(new_doc.body.visible_text).not_to include('USER_AGENT: foo')
        expect(new_doc.body.visible_text).not_to include('HOST: foo.com')
      end

      it 'does set header only in current window' do
        new_doc = @doc.open_new_document
        @doc.set_extra_headers(
          'Xtra' => 'foo=bar',
          'Host' => 'foo.com'
        )
        @doc.set_user_agent('foo')

        @doc.visit('/puppetmaster/headers')
        expect(@doc.body.visible_text).to include('XTRA: foo=bar')
        expect(@doc.body.visible_text).to include('USER_AGENT: foo')
        expect(@doc.body.visible_text).to include('HOST: foo.com')

        new_doc.visit('/puppetmaster/headers')
        expect(new_doc.body.visible_text).not_to include('XTRA: foo=bar')
        expect(new_doc.body.visible_text).not_to include('USER_AGENT: foo')
        expect(new_doc.body.visible_text).not_to include('HOST: foo.com')
      end
    end
  end

  shared_examples 'javascript' do
    it 'supports executing multiple lines of javascript' do
      @doc = visit('/')
      @doc.execute_script <<~JS
            var a = 1;
            var b = 2;
            window.result = a + b;
      JS
      expect(@doc.evaluate_script('window.result')).to eq(3)
    end

    context 'javascript errors' do
      it 'propagates a synchronous Javascript error on the page to a ruby exception' do
        @doc = visit('/')
        expect do
          @doc.execute_script 'omg'
        end.to raise_error(Isomorfeus::Puppetmaster::JavaScriptError, /.*omg/)
      end
    end
  end

  shared_examples 'javascript load errors' do
    it 'propagates a Javascript error during page load to a ruby exception' do
      expect { @doc = visit '/puppetmaster/js_error' }.to raise_error(Isomorfeus::Puppetmaster::JavaScriptError, /ReferenceError/)
    end
  end

  shared_examples 'mouse' do
    it 'supports clicking precise coordinates' do
      @doc = visit('/puppetmaster/click_coordinates')
      @doc.click(x: 100, y: 150)
      expect(@doc.body.visible_text).to include('x: 100, y: 150')
    end
  end

  shared_examples 'render screen' do
    it 'supports format' do
      @doc = visit('/')

      @doc.save_screenshot(file, format: format)
      case format
      when :png
        expect(FastImage.type(file)).to eq :png
      when :jpeg
        expect(FastImage.type(file)).to eq :jpeg
      else
        raise 'Unknown format'
      end
    end

    it 'supports rendering the whole of a page that goes outside the viewport' do
      @doc = visit('/puppetmaster/long_page')

      @doc.save_screenshot file
      expect(FastImage.size(file)).to eq(
                                        @doc.evaluate_script('[window.innerWidth, window.innerHeight]')
                                      )

      @doc.save_screenshot file, full: true
      expect(FastImage.size(file)).to eq(
                                        @doc.evaluate_script('[document.documentElement.clientWidth, document.documentElement.clientHeight]')
                                      )
    end

    it 'supports rendering the entire window when documentElement has no height' do
      @doc = visit('/puppetmaster/fixed_positioning')

      @doc.save_screenshot file, full: true
      expect(FastImage.size(file)).to eq(
                                        @doc.evaluate_script('[window.innerWidth, window.innerHeight]')
                                      )
    end

    it 'supports rendering just the selected element' do
      @doc = visit('/puppetmaster/long_page')
      @doc.find('#penultimate').save_screenshot(file)
      x, y = FastImage.size(file)
      k, i = @doc.evaluate_script <<~JS
            function() {
              var rect = document.getElementById('penultimate').getBoundingClientRect();
              return [rect.width, rect.height];
            }();
      JS
      # firefox shows subpixels
      expect([x, y]).to eq([k, i.to_i])
    end

    it 'resets element positions after' do
      @doc = visit('/puppetmaster/long_page')
      el = @doc.find('#middleish')
      # make the page scroll an element into view
      el.click
      position_script = 'document.querySelector("#middleish").getBoundingClientRect()'
      offset = @doc.evaluate_script(position_script)
      @doc.save_screenshot file
      expect(@doc.evaluate_script(position_script)).to eq offset
    end
  end

  shared_examples 'render_base64' do
    let(:format) { :png }
    let(:tempfile) { Tempfile.new(['screenshot', ".#{format}"]) }
    let(:file) { tempfile.path }
    let(:doc) { visit('/') }

    def create_screenshot(file, **options)
      image = doc.render_base64(options.merge(format: format))
      File.open(file, 'wb') { |f| f.write Base64.decode64(image) }
      image
    end

    it 'supports rendering the page in base64' do
      doc.visit('/')

      screenshot = create_screenshot(file)

      expect(screenshot.length).to be > 100
    end

    context 'png' do
      let(:format) { :png }

      include_examples 'render screen'
    end

    context 'jpeg' do
      let(:format) { :jpeg }

      include_examples 'render screen'
    end
  end

  shared_examples 'save_pdf' do
    let(:tempfile) { Tempfile.new(['screenshot', ".pdf"]) }
    let(:file) { tempfile.path }

    it 'changes pdf size with width and height' do
      doc = visit('/puppetmaster/long_page')

      doc.save_pdf(file, width: '1in', height: '1in')
      reader = PDF::Reader.new(file)
      reader.pages.each do |page|
        bbox   = page.attributes[:MediaBox]
        width  = (bbox[2] - bbox[0]) / 72
        expect(width).to eq(1)
      end
    end

    it 'changes pdf size with page format' do
      doc = visit('/puppetmaster/long_page')

      doc.save_pdf(file, format: 'Ledger')
      reader = PDF::Reader.new(file)
      reader.pages.each do |page|
        bbox   = page.attributes[:MediaBox]
        width  = (bbox[2] - bbox[0]) / 72
        expect(width).to eq(17)
      end
    end
  end

  shared_examples 'save_screenshot' do
    let(:format) { :png }
    let(:tempfile) { Tempfile.new(['screenshot', ".#{format}"]) }
    let(:file) { tempfile.path }
    let(:doc) { visit('/') }

    it 'supports rendering the page' do
      doc.visit('/')
      doc.save_screenshot(file)
      expect(File.exist?(file)).to be true
      expect(FastImage.type(file)).to be format
    end

    it 'supports rendering the page with a nonstring path' do
      doc.visit('/')
      doc.save_screenshot(Pathname(file))
      expect(File.exist?(file)).to be true
    end

    it 'supports rendering the page to file without extension when format is specified' do
      file = Tempfile.new
      doc.visit('/')

      doc.save_screenshot(file.path, format: 'jpg')

      expect(FastImage.type(file.path)).to be :jpeg
    end

    it 'supports rendering the page with different quality settings' do
      # only jpeg supports quality
      skip 'doesnt work with firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      file1 = Tempfile.new(['screenshot1-', '.jpg'])
      file2 = Tempfile.new(['screenshot1-', '.jpg'])
      file3 = Tempfile.new(['screenshot1-', '.jpg'])

      begin
        doc.visit('/')
        doc.save_screenshot(file1, format: :jpeg, quality: 10)
        doc.save_screenshot(file2, format: :jpeg, quality: 50)
        doc.save_screenshot(file3, format: :jpeg, quality: 100)

        expect(File.size(file1)).to be < File.size(file2)
        expect(File.size(file2)).to be < File.size(file3)
      end
    end

    context 'png' do
      let(:format) { :png }

      include_examples 'render screen'
    end

    context 'jpeg' do
      let(:format) { :jpeg }

      include_examples 'render screen'
    end
  end

  shared_examples 'scrolling' do
    it 'allows the page to be scrolled' do
      doc = visit('/puppetmaster/long_page')
      doc.viewport_resize(100, 50)
      doc.scroll_to(200, 100)

      expect(
        doc.evaluate_script('[window.scrollX, window.scrollY]')
      ).to eq([200, 100])
      doc.viewport_resize(Isomorfeus::Puppetmaster::Driver::Puppeteer::VIEWPORT_DEFAULT_WIDTH, Isomorfeus::Puppetmaster::Driver::Puppeteer::VIEWPORT_DEFAULT_HEIGHT)
    end
  end

  shared_examples 'set content editable value' do
    before { @doc = visit('/puppetmaster/set') }

    it "sets a contenteditable's content" do
      input = @doc.find('#filled_div')
      input.value = 'new text'
      expect(input.text).to eq('new text')
    end

    it "sets multiple contenteditables' content" do
      input = @doc.find('#empty_div')
      input.value = 'new text'

      expect(input.text).to eq('new text')

      input = @doc.find('#filled_div')
      input.value = 'replacement text'

      expect(input.text).to eq('replacement text')
    end

    it 'sets a content editable childs content' do
      @doc = visit('/with_js')
      @doc.find('#existing_content_editable_child').value = 'WYSIWYG'
      expect(@doc.find('#existing_content_editable_child').text).to eq('WYSIWYG')
    end
  end

  shared_examples 'date fields' do
    before { @doc = visit('/puppetmaster/date_fields') }

    it 'sets a date' do
      input = @doc.find('#date_field')
      input.value = Date.parse('2016-02-14')
      expect(input.value).to eq('2016-02-14')
    end
  end

  shared_examples 'date fields enhanced' do
    before { @doc = visit('/puppetmaster/date_fields') }

    it 'sets a date via keystrokes' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#date_field')
      input.type_keys :arrow_left, :arrow_left, '14022016'
      expect(input.value).to eq('2016-02-14')
    end
  end

  shared_examples 'type keys' do
    before { @doc = visit('/puppetmaster/send_keys') }

    it 'sends keys to empty input' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#empty_input')
      input.type_keys('Input')
      expect(input.value).to eq('Input')
    end

    it 'types to empty input' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#empty_input')
      input.type_keys('Input')
      expect(input.value).to eq('Input')
    end

    it 'sends keys to empty textarea' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#empty_textarea')
      input.type_keys('Input')
      expect(input.value).to eq('Input')
    end

    it 'sends sequences with modifiers and letters' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#empty_input')
      input.type_keys([:shift, 's', 't'], 'r', 'i', 'n', 'g')
      expect(input.value).to eq('STring')
    end

    it 'sends modifiers with sequences' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#empty_input')
      input.type_keys('s', [:shift, 'tring'])
      expect(input.value).to eq('sTRING')
    end
  end

  shared_examples 'type keys enhanced' do
    before { @doc = visit('/puppetmaster/send_keys') }

    it 'sends keys to empty contenteditable div' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#empty_div')
      input.type_keys('Input')
      expect(input.text).to eq('Input')
    end

    it 'in sequences' do
      skip 'todo for firefox' if %i[firefox firefox_debug].include?(Isomorfeus::Puppetmaster.driver)
      input = @doc.find('#empty_input')
      input.type_keys([:shift, 's', 't'], 'r', 'i', 'g', :arrow_left, 'n')
      expect(input.value).to eq('STring')
    end

    it 'sends sequences with modifiers and symbols' do
      input = @doc.find('#empty_input')
      input.type_keys('t', 'r', 'i', 'n', 'g', [OS.mac? ? :alt : :control, :arrow_left], 's')
      expect(input.value).to eq('string')
    end

    it 'sends sequences with multiple modifiers and symbols' do
      input = @doc.find('#empty_input')
      input.type_keys('t', 'r', 'i', 'n', 'g', [OS.mac? ? :alt : :control, :shift, :arrow_left], 's')
      expect(input.value).to eq('s')
    end

    it 'sends modifiers with multiple keys' do
      input = @doc.find('#empty_input')
      input.type_keys('puppet', %i[shift arrow_left arrow_left], 'master')
      expect(input.value).to eq('puppmaster')
    end

    it 'submits the form with sequence' do
      input = @doc.find('#without_submit_button input')
      input.type_keys(:Enter)
      expect(input.value).to eq('Submitted')
    end

    it 'supports old Poltergeist mixed case allowed key naming' do
      input = @doc.find('#empty_input')
      input.type_keys(:PageUp, :page_up)
      expect(@doc.find('#key-events-output')).to have_text('keydown:33 keyup:33', count: 2)
    end

    it 'generates correct events with keyCodes for modified punctuation' do
      input = @doc.find('#empty_input')
      input.type_keys([:shift, '.'], [:shift, 't'])
      expect(@doc.find('#key-events-output')).to have_text('keydown:16 keydown:190 keyup:190 keyup:16 keydown:16 keydown:84 keyup:84 keyup:16')
    end

    it 'supports :control and :Ctrl and :ctrl aliases' do
      input = @doc.find('#empty_input')
      input.type_keys([:Ctrl, 'a'], [:control, 'a'], [:control, 'a'])
      expect(@doc.find('#key-events-output')).to have_text('keydown:17 keydown:65 keyup:65 keyup:17', count: 3)
    end

    it 'supports :command and :Meta and :meta aliases' do
      input = @doc.find('#empty_input')
      input.type_keys([:Meta, 'z'], [:command, 'z'], [:meta, 'z'])
      expect(@doc.find('#key-events-output')).to have_text('keydown:91 keydown:90 keyup:90 keyup:91', count: 3)
    end

    it 'supports standard Chrome USKeyboardLayout.js specified numpad keys' do
      input = @doc.find('#empty_input')
      input.type_keys(:numpad2, :numpad8, :divide, :decimal)
      expect(@doc.find('#key-events-output')).to have_text('keydown:40 keyup:40 keydown:38 keyup:38 keydown:111 keyup:111 keydown:46 keyup:46')
    end

    it 'errors when unknown key' do
      input = @doc.find('#empty_input')
      expect do
        input.type_keys('abc', :blah)
      end.to raise_error Isomorfeus::Puppetmaster::KeyError, "Unknown key: \"Blah\""
    end
  end

  shared_examples 'viewport' do
    before do
      @doc = visit('/')
    end
    after do
      @doc.viewport_resize(Isomorfeus::Puppetmaster::Driver::Puppeteer::VIEWPORT_DEFAULT_WIDTH, Isomorfeus::Puppetmaster::Driver::Puppeteer::VIEWPORT_DEFAULT_HEIGHT)
    end

    it 'has a viewport size of 1024x768 by default' do
      expect(
        @doc.evaluate_script('[window.innerWidth, window.innerHeight]')
      ).to eq([1024, 768])
    end

    it 'allows the viewport to be resized' do
      @doc.viewport_resize(200, 400)
      expect(
        @doc.evaluate_script('[window.innerWidth, window.innerHeight]')
      ).to eq([200, 400])
    end

    it 'defaults viewport maximization to 1366x768' do
      @doc.viewport_maximize
      expect(@doc.viewport_size).to eq([1366, 768])
    end
  end
end