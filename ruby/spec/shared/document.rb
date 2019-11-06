# frozen_string_literal: true

module PuppetmasterSpec
  shared_examples 'document and node extra enhanced' do
    before do
      @doc = open_new_document
    end

    it 'ignores cyclic structure errors in evaluate_script' do
      code = <<~JS
        (function() {
          var a = {};
          var b = {};
          var c = {};
          c.a = a;
          a.a = a;
          a.b = b;
          a.c = c;
          return a;
        })()
      JS
      expect(@doc.evaluate_script(code)).to eq('a' => '(cyclic structure)', 'b' => {}, 'c' => { 'a' => '(cyclic structure)' })
    end
  end

  shared_examples 'document and node enhanced' do
    before do
      @doc = open_new_document
    end

    it 'has no trouble clicking elements when the size of a document changes' do
      @doc.visit('/puppetmaster/long_page')
      @doc.find('#penultimate').click
      @doc.execute_script <<~JS
        el = document.getElementById('penultimate')
        el.parentNode.removeChild(el)
      JS
      @doc.find_by_content('Phasellus blandit velit').click
      expect(@doc).to have_content('Hello')
    end

    it 'handles clicks where the target is in view, but the document is smaller than the viewport' do
      @doc.visit '/puppetmaster/simple'
      @doc.find_by_content('Link').click
      expect(@doc).to have_content('Hello world')
    end

    it 'handles clicks where a parent element has a border' do
      @doc.visit '/puppetmaster/table'
      @doc.find_by_content('Link').click
      expect(@doc).to have_content('Hello world')
    end

    it 'handles evaluate_script values properly' do
      @doc.visit '/'
      expect(@doc.evaluate_script('null')).to be_nil
      expect(@doc.evaluate_script('false')).to be false
      expect(@doc.evaluate_script('true')).to be true
      expect(@doc.evaluate_script("{foo: 'bar'}")).to eq('foo' => 'bar')
    end

    it 'synchronises page loads properly' do
      @doc.visit '/puppetmaster/index'
      @doc.find_by_content('JS redirect').click
      expect(@doc.html).to include('Hello world')
    end

    it 'returns BR as \\n in #text' do
      @doc.visit '/puppetmaster/simple'
      expect(@doc.find('#break').visible_text).to eq("Foo\nBar")
    end

    it 'handles hash changes' do
      @doc.visit '/#omg'
      expect(@doc.url).to match(%r{/#omg$})
      @doc.execute_script <<~JS
        window.onhashchange = function() { window.last_hashchange = window.location.hash }
      JS
      @doc.visit '/#foo'
      expect(@doc.url).to match(%r{/#foo$})
      expect(@doc.evaluate_script('window.last_hashchange')).to eq('#foo')
    end

    it 'knows about its parents' do
      @doc.visit '/puppetmaster/simple'
      parents = @doc.find('#nav').parents
      expect(parents.map(&:tag)).to eq %w[li ul body html]
    end

    it 'can go back when history state has been pushed' do
      @doc.visit('/')
      @doc.execute_script('window.history.pushState({foo: "bar"}, "title", "bar2.html");')
      expect(@doc).to have_current_path('/bar2.html')
      expect { @doc.go_back }.not_to raise_error
      expect(@doc).to have_current_path('/')
    end

    it 'can go forward when history state is used' do
      @doc.visit('/')
      @doc.execute_script('window.history.pushState({foo: "bar"}, "title", "bar2.html");')
      expect(@doc).to have_current_path('/bar2.html')
      # don't use #go_back here to isolate the test
      @doc.execute_script('window.history.go(-1);')
      expect(@doc).to have_current_path('/')
      expect { @doc.go_forward }.not_to raise_error
      expect(@doc).to have_current_path('/bar2.html')
    end

    describe Isomorfeus::Puppetmaster::Node do
      it 'raises an error if the element was on a previous page' do
        @doc.visit('/puppetmaster/index')
        node = @doc.find_xpath('.//a')
        @doc.execute_script "window.location = 'about:blank'"
        sleep 0.1 # allow the window time to load new location
        expect { node.visible_text }.to raise_error(Isomorfeus::Puppetmaster::ExecutionContextError)
      end

      context 'when the element is not in the viewport' do
        before do
          @doc.visit('/puppetmaster/with_js')
        end

        it 'raises a MouseEventFailed error' do
          skip 'todo'
          expect { @doc.find_by_content('O hai').click }.to raise_error(Isomorfeus::Puppetmaster::MouseEventFailed)
        end

        context 'and is then brought in' do
          before do
            @doc.execute_script "$('#off-the-left').animate({left: '10'});"
          end

          it 'clicks properly' do
            skip 'todo'
            expect { @doc.find_by_content('O hai').click }.not_to raise_error
          end
        end
      end
    end

    describe 'Node#visible' do
      before do
        @doc.visit('/puppetmaster/visible')
      end

      it 'considers display: none to not be visible' do
        skip 'todo'
        expect(@doc.find(:css, 'li', text: 'Display None', visible: false).visible?).to be false
      end

      it 'considers visibility: hidden to not be visible' do
        skip 'todo'
        expect(@doc.find(:css, 'li', text: 'Hidden', visible: false).visible?).to be false
      end

      it 'considers opacity: 0 to not be visible' do
        skip 'todo'
        expect(@doc.find(:css, 'li', text: 'Transparent', visible: false).visible?).to be false
      end

      it 'element with all children hidden returns empty text' do
        expect(@doc.find('div').visible_text).to eq('')
      end
    end

    context 'click tests' do
      before do
        @doc.visit '/puppetmaster/click_test'
        @orig_size = @doc.viewport_size
      end

      after do
        @doc.viewport_resize(*@orig_size)
      end

      it 'scrolls around so that elements can be clicked' do
        @doc.viewport_resize(200, 200)
        log = @doc.find('#log')

        instructions = %w[one four one two three]
        instructions.each do |instruction, _i|
          @doc.find("##{instruction}").click
          expect(log.visible_text).to eq(instruction)
        end
      end

      # See https://github.com/teampuppetmaster/puppetmaster/issues/60
      it 'fixes some weird layout issue that we are not entirely sure about the reason for' do
        @doc.visit '/puppetmaster/datepicker'
        @doc.find('#datepicker').value = '2012-05-11'
        @doc.find_by_content('some link').click
      end

      it 'can click an element inside an svg' do
        expect do
          @doc.find('#myrect').click
        end.not_to raise_error
      end

      context 'with #two overlapping #one' do
        before do
          @doc.execute_script <<~JS
            var two = document.getElementById('two')
            two.style.position = 'absolute'
            two.style.left     = '0px'
            two.style.top      = '0px'
          JS
          @doc.execute_script('window.scrollTo(0,0)')
        end

        it 'detects if an element is obscured when clicking' do
          skip 'todo'
          expect do
            @doc.find('#one').click
          end.to raise_error(Isomorfeus::Puppetmaster::MouseEventFailed) { |error|
            # expect(error.selector).to eq('html body div#two.box')
            expect(error.selector).to match(/div#two/)
            expect(error.message).to match(/at co-ordinates \[\d+, \d+\]/)
          }
        end

        it 'clicks in the centre of an element' do
          skip 'todo'
          expect do
            @doc.find('#one').click
          end.to raise_error(Isomorfeus::Puppetmaster::MouseEventFailed) { |error|
            expect(error.position).to eq([200, 200])
          }
        end

        it 'clicks in the centre of an element within the viewport, if part is outside the viewport' do
          skip 'todo'
          @doc.current_window.resize_to(200, 200)

          expect do
            @doc.find('#one').click
          end.to raise_error(Isomorfeus::Puppetmaster::MouseEventFailed) { |error|
            expect(error.position.first).to eq(150)
          }
        end
      end

      context 'with #svg overlapping #one' do
        before do
          @doc.execute_script <<~JS
            var two = document.getElementById('svg')
            two.style.position = 'absolute'
            two.style.left     = '0px'
            two.style.top      = '0px'
          JS
          @doc.execute_script('window.scrollTo(0,0)')
        end

        it 'detects if an element is obscured when clicking' do
          skip 'todo'
          expect do
            @doc.find('#one').click
          end.to raise_error(Isomorfeus::Puppetmaster::MouseEventFailed) { |error|
            # TODO: improve the error selector - but it could be from a parent frame
            expect(error.selector).to match(/svg#svg/)
            expect(error.message).to include('[200, 200]')
          }
        end
      end

      context 'with image maps' do
        before do
          @doc.visit('/puppetmaster/image_map')
        end

        it 'can click' do
          @doc.find('map[name=testmap] area[shape=circle]').click
          expect(@doc).to have_css('#log', text: 'circle clicked')
          @doc.find('map[name=testmap] area[shape=rect]').click
          expect(@doc).to have_css('#log', text: 'rect clicked')
        end

        it "doesn't click if the associated img is hidden" do
          skip 'todo'
          expect do
            @doc.find('map[name=testmap2] area[shape=circle]').click
          end.to raise_error(Capybara::ElementNotFound)
          expect do
            @doc.find('map[name=testmap2] area[shape=circle]', visible: false).click
          end.to raise_error(Isomorfeus::Puppetmaster::MouseEventFailed)
        end
      end
    end

    context 'double click tests' do
      before do
        @doc.visit '/puppetmaster/double_click_test'
        @orig_size = @doc.viewport_size
      end

      after { @doc.viewport_resize(*@orig_size) }

      it 'double clicks properly' do
        @doc.viewport_resize(200, 200)
        log = @doc.find('#log')

        instructions = %w[one four one two three]
        instructions.each do |instruction, _i|
          @doc.find("##{instruction}").double_click
          expect(log.visible_text).to eq(instruction)
        end
      end
    end

    context 'basic dragging support' do
      before do
        @doc.visit '/puppetmaster/drag'
      end

      it 'supports drag_to' do
        draggable = @doc.find('#drag_to #draggable')
        droppable = @doc.find('#drag_to #droppable')

        draggable.drag_to(droppable)
        expect(droppable).to have_content('Dropped')
      end

      it 'supports drag_by on native element' do
        skip 'todo'
        draggable = @doc.find('#drag_by .draggable')

        top_before = @doc.evaluate_script('$("#drag_by .draggable").position().top')
        left_before = @doc.evaluate_script('$("#drag_by .draggable").position().left')

        draggable.native.drag_by(15, 15)

        top_after = @doc.evaluate_script('$("#drag_by .draggable").position().top')
        left_after = @doc.evaluate_script('$("#drag_by .draggable").position().left')

        expect(top_after).to eq(top_before + 15)
        expect(left_after).to eq(left_before + 15)
      end
    end

    context 'HTML5 dragging support' do
      before do
        @doc.visit '/with_js'
      end

      it 'should HTML5 drag and drop an object' do
        element = @doc.find_xpath('//div[@id="drag_html5"]')
        target = @doc.find_xpath('//div[@id="drop_html5"]')
        element.drag_to(target)
        expect(@doc).to have_xpath('//div[contains(., "HTML5 Dropped drag_html5")]')
      end

      it 'should set clientX/Y in dragover events' do
        skip 'todo'
        element = @doc.find_xpath('//div[@id="drag_html5"]')
        target = @doc.find_xpath('//div[@id="drop_html5"]')
        element.drag_to(target)
        expect(@doc).to have_css('div.log', text: /DragOver with client position: [1-9]\d*,[1-9]\d*/, count: 2)
      end

      it 'should not HTML5 drag and drop on a non HTML5 drop element' do
        skip 'todo'
        element = @doc.find_xpath('//div[@id="drag_html5"]')
        target = @doc.find_xpath('//div[@id="drop_html5"]')
        target.execute_script("$(this).removeClass('drop');")
        element.drag_to(target)
        sleep 1
        expect(@doc).not_to have_xpath('//div[contains(., "HTML5 Dropped drag_html5")]')
      end

      it 'should HTML5 drag and drop when scrolling needed' do
        element = @doc.find_xpath('//div[@id="drag_html5_scroll"]')
        target = @doc.find_xpath('//div[@id="drop_html5_scroll"]')
        element.drag_to(target)
        expect(@doc).to have_xpath('//div[contains(., "HTML5 Dropped drag_html5_scroll")]')
      end

      it 'should drag HTML5 default draggable elements' do
        link = @doc.find('#drag_link_html5')
        target = @doc.find('#drop_html5')
        link.drag_to target
        expect(@doc).to have_xpath('//div[contains(., "HTML5 Dropped")]')
      end
    end
  end

  shared_examples 'document and node' do
    before do
      @doc = open_new_document
    end

    after do
      # @doc.reset!
    end

    describe Isomorfeus::Puppetmaster::Node do
      it 'raises an error if the element has been removed from the DOM' do
        skip 'todo'
        @doc.visit('/puppetmaster/with_js')
        node = @doc.find('#remove_me')
        expect(node.text).to eq('Remove me')
        @doc.find('#remove').click
        expect { node.visible_text }.to raise_error(Isomorfeus::Puppetmaster::ExecutionContextError)
      end

      it 'raises an error if the element is not visible' do
        skip 'todo'
        @doc.visit('/puppetmaster/index')
        @doc.execute_script "document.querySelector('a[href=js_redirect]').style.display = 'none'"
        expect { @doc.find_by_content('JS redirect').click }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it 'hovers an element' do
        skip 'todo'
        @doc.visit('/puppetmaster/with_js')
        expect(@doc.find('#hidden_link span', visible: false)).not_to be_visible
        @doc.find('#hidden_link').hover
        expect(@doc.find('#hidden_link span')).to be_visible
      end

      it 'hovers an element before clicking it' do
        skip 'todo'
        @doc.visit('/puppetmaster/with_js')
        @doc.find_by_content('Hidden link').click
        expect(@doc.current_path).to eq('/')
      end

      it 'does not raise error when asserting svg elements with a count that is not what is in the dom' do
        @doc.visit('/puppetmaster/with_js')
        expect { @doc.has_css?('svg circle', count: 2) }.not_to raise_error
        expect(@doc).not_to have_css('svg circle', count: 2)
      end

      context 'when someone (*cough* prototype *cough*) messes with Array#toJSON' do
        before do
          @doc.visit('/puppetmaster/index')
          array_munge = <<~JS
            Array.prototype.toJSON = function() {
              return "ohai";
            }
          JS
          @doc.execute_script array_munge
        end

        it 'gives a proper error' do
          expect { @doc.find('username') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
        end
      end

      context 'when someone messes with JSON' do
        # mootools <= 1.2.4 replaced the native JSON with it's own JSON that didn't have stringify or parse methods
        it 'works correctly' do
          @doc.visit('/puppetmaster/index')
          @doc.execute_script('JSON = {};')
          expect { @doc.find_by_content('JS redirect') }.not_to raise_error
        end
      end
    end

    context 'when the element is not in the viewport of parent element' do
      before do
        @doc.visit('/puppetmaster/scroll')
      end

      it 'scrolls into view' do
        skip 'todo'
        @doc.find_by_content('Link outside viewport').click
        expect(@doc.current_path).to eq('/')
      end

      it 'scrolls into view if scrollIntoViewIfNeeded fails' do
        skip 'todo'
        @doc.find_by_content('Below the fold').click
        expect(@doc.current_path).to eq('/')
      end
    end

    describe 'Node#select' do
      before do
        @doc.visit('/puppetmaster/with_js')
      end

      context 'when selected option is not in optgroup' do
        it 'fires the focus event' do
          skip 'todo'
          expect(@doc.find(:css, '#changes_on_focus').text).to eq('puppetmaster')
        end

        it 'fire the change event' do
          skip 'todo'
          expect(@doc.find(:css, '#changes').text).to eq('Firefox')
        end

        it 'fires the blur event' do
          skip 'todo'
          expect(@doc.find(:css, '#changes_on_blur').text).to eq('Firefox')
        end

        it 'fires the change event with the correct target' do
          skip 'todo'
          expect(@doc.find(:css, '#target_on_select').text).to eq('SELECT')
        end
      end

      context 'when selected option is in optgroup' do
        before do
          # @doc.find(:select, 'browser').find(:option, 'Safari').select_option
        end

        it 'fires the focus event' do
          skip 'todo'
          expect(@doc.find(:css, '#changes_on_focus').text).to eq('puppetmaster')
        end

        it 'fire the change event' do
          skip 'todo'
          expect(@doc.find(:css, '#changes').text).to eq('Safari')
        end

        it 'fires the blur event' do
          skip 'todo'
          expect(@doc.find(:css, '#changes_on_blur').text).to eq('Safari')
        end

        it 'fires the change event with the correct target' do
          skip 'todo'
          expect(@doc.find(:css, '#target_on_select').text).to eq('SELECT')
        end
      end
    end

    describe 'Node#value=' do
      before do
        @doc.visit('/puppetmaster/with_js')
        @doc.find('#change_me').value = 'Hello!'
      end

      it 'fires the change event' do
        skip 'todo'
        # click outside the field to trigger the change event
        @doc.find('body').click
        expect(@doc.find('#changes').visible_text).to eq('Hello!')
      end

      it 'fires the input events' do
        skip 'todo'
        expect(@doc.find('#changes_on_input').visible_text).to eq('Hello!')
      end

      it 'accepts numbers in a maxlength field' do
        element = @doc.find('#change_me_maxlength')
        element.value = 100
        expect(element.value).to eq('100')
      end

      it 'accepts negatives in a number field' do
        element = @doc.find('#change_me_number')
        element.value = -100
        expect(element.value).to eq('-100')
      end

      it 'fires the keydown event' do
        skip 'todo' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#changes_on_keydown').visible_text).to eq('6')
      end

      it 'fires the keyup event' do
        skip 'todo' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#changes_on_keyup').visible_text).to eq('6')
      end

      it 'fires the keypress event' do
        skip 'todo' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#changes_on_keypress').visible_text).to eq('6')
      end

      it 'fires the focus event' do
        skip 'todo' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#changes_on_focus').visible_text).to eq('Focus')
      end

      it 'fires the blur event' do
        # click outside the field to trigger the blur event
        skip 'todo'
        @doc.find('body').click
        expect(@doc.find('#changes_on_blur').visible_text).to eq('Blur')
      end

      it 'fires the keydown event before the value is updated' do
        skip 'todo' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#value_on_keydown').visible_text).to eq('Hello')
      end

      it 'fires the keyup event after the value is updated' do
        skip 'todo' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#value_on_keyup').visible_text).to eq('Hello!')
      end

      it 'clears the input before setting the new value' do
        element = @doc.find('#change_me')
        element.value= ''
        expect(element.value).to eq('')
      end

      it 'supports special characters' do
        element = @doc.find('#change_me')
        element.value= '$52.00'
        expect(element.value).to eq('$52.00')
      end

      it 'attaches a file when passed a Pathname' do
        skip 'todo'
        file = Tempfile.create('a_test_pathname') do |f|
          f.write('text')
          f
        end
        element = @doc.find('#change_me_file').value= file.path
        expect(element.value).to match(/^C:\\fakepath\\a_test_pathname/)
      end
    end

    describe 'Node#checked?' do
      before do
        @doc.visit '/puppetmaster/attributes_properties'
      end

      it 'is a boolean' do
        skip 'todo'
        expect(@doc.find_field('checked').checked?).to be true
        expect(@doc.find_field('unchecked').checked?).to be false
      end
    end

    describe 'Node#[]' do
      before do
        @doc.visit '/puppetmaster/attributes_properties'
      end

      it 'gets normalized href' do
        skip 'todo'
        expect(@doc.find_by_content('Loop')['href']).to eq("http://#{Isomorfeus::Puppetmaster.server_host}:#{Isomorfeus::Puppetmaster.server_port}/puppetmaster/attributes_properties")
      end

      it 'gets innerHTML' do
        expect(@doc.find('.some_other_class').inner_html).to eq '<p>foobar</p>'
      end

      it 'gets attribute' do
        link = @doc.find_by_content('Loop')
        expect(link['data-random']).to eq '42'
        expect(link['onclick']).to eq 'return false;'
      end

      it 'gets boolean attributes as booleans' do
        skip 'todo'
        expect(@doc.find_field('checked')['checked']).to be true
        expect(@doc.find_field('unchecked')['checked']).to be false
      end
    end

    describe 'Node#==' do
      it "doesn't equal a node from another page" do
        @doc.visit('/puppetmaster/simple')
        @elem1 = @doc.find('#nav')
        @doc.visit('/puppetmaster/set')
        @elem2 = @doc.find('#filled_div')
        expect(@elem2 == @elem1).to be false
        expect(@elem1 == @elem2).to be false
      end

      it 'equals if the same node' do
        @doc.visit('/puppetmaster/set')
        @elem1 = @doc.find('#filled_div')
        @elem2 = @doc.find('#filled_div')
        expect(@elem1 == @elem2).to be true
      end
    end

    it 'handles window.confirm(), returning true unconditionally' do
      skip 'todo'
      @doc.visit '/'
      expect(@doc.evaluate_script("window.confirm('foo')")).to be true
    end

    it 'handles window.prompt(), returning the default value or null' do
      skip 'todo'
      @doc.visit '/'
      expect(@doc.evaluate_script("window.prompt('foo', 'default')")).to eq('default')
    end

    it 'can evaluate a statement ending with a semicolon' do
      expect(@doc.evaluate_script('3;')).to eq(3)
    end

    it 'returns element when no elements passed in' do
      skip 'not applicable'
      @doc.visit('/with_js')
      change = @doc.find('#change')
      el = @doc.evaluate_script("document.getElementById('change')")
      expect(el).to be_instance_of(Capybara::Node::Element)
      expect(el).to eq(change)
    end

    it 'returns element when element passed in' do
      skip 'not applicable'
      @doc.visit('/with_js')
      change = @doc.find(:css, '#change')
      el = @doc.evaluate_script('arguments[0]', change)
      expect(el).to be_instance_of(Capybara::Node::Element)
      expect(el).to eq(change)
    end

    context 'status code support', :status_code_support do
      it 'determines status code when an user goes to a page by using a link on it' do
        skip 'todo'
        @doc.visit '/puppetmaster/with_different_resources'

        @doc.find_by_content('Go to 500').click
        expect(@doc.response.status).to eq(500)
      end

      it 'determines properly status code when an user goes through a few pages' do
        skip 'todo'
        @doc.visit '/puppetmaster/with_different_resources'
        sleep 0.1
        @doc.find_by_content('Go to 201').click
        sleep 0.1
        @doc.find_by_content('Do redirect').click
        sleep 0.1
        @doc.find_by_content('Go to 402').click
        sleep 0.1
        expect(@doc.response.status).to eq(402)
      end
    end

    context 'current_url' do
      let(:request_uri) { URI.parse(@doc.url).request_uri }

      it 'supports whitespace characters' do
        @doc.visit '/puppetmaster/arbitrary_path/200/foo%20bar%20baz'
        expect(@doc.path).to eq('/puppetmaster/arbitrary_path/200/foo%20bar%20baz')
      end

      it 'supports escaped characters' do
        @doc.visit '/puppetmaster/arbitrary_path/200/foo?a%5Bb%5D=c'
        expect(request_uri).to eq('/puppetmaster/arbitrary_path/200/foo?a%5Bb%5D=c')
      end

      it 'supports url in parameter' do
        @doc.visit '/puppetmaster/arbitrary_path/200/foo%20asd?a=http://example.com/asd%20asd'
        expect(request_uri).to eq('/puppetmaster/arbitrary_path/200/foo%20asd?a=http://example.com/asd%20asd')
      end

      it 'supports restricted characters " []:/+&="' do
        @doc.visit '/puppetmaster/arbitrary_path/200/foo?a=%20%5B%5D%3A%2F%2B%26%3D'
        expect(request_uri).to eq('/puppetmaster/arbitrary_path/200/foo?a=%20%5B%5D%3A%2F%2B%26%3D')
      end
    end

    context 'multiple docs viewport support' do
      describe '#size' do
        # We base size on innerWidth and innerHeight since each "tab" can have its own size
        # This replaces some Capybara tests which fail to the use of outerWidth and outerHeight

        def win_size
          @doc.evaluate_script('[window.innerWidth, window.innerHeight]')
        end

        it 'should return size of whole viewport', requires: %i[windows js] do
          expect(@doc.viewport_size).to eq win_size
        end

        it 'should switch between docs' do
          skip 'todo'
          @doc.visit('/with_windows')

          @other_doc = @doc.document_opened_by do
            @doc.find('#openWindow').click
          end

          size = win_size

          expect(@other_doc.viewport_size).to eq(size)
          @other_doc.close
        end
      end
    end

    context 'frame support', requires: [:frames] do
      it 'supports selection by index' do
        skip 'todo'
        @doc.visit '/puppetmaster/frames'
        @doc.within_frame 0 do
          sleep 1
          expect(@doc.driver.frame_url).to match %r{/puppetmaster/slow$}
        end
      end

      it 'supports selection by element' do
        skip 'todo'
        @doc.visit '/puppetmaster/frames'
        frame = @doc.find(:css, 'iframe[name]')

        @doc.within_frame(frame) do
          sleep 1
          expect(@doc.driver.frame_url).to match %r{/puppetmaster/slow$}
        end
      end

      it 'supports selection by element without name or id' do
        skip 'todo'
        @doc.visit '/puppetmaster/frames'
        frame = @doc.find(:css, 'iframe:not([name]):not([id])')

        @doc.within_frame(frame) do
          sleep 1
          expect(@doc.driver.frame_url).to match %r{/puppetmaster/headers$}
        end
      end

      it 'supports selection by element with id but no name' do
        skip 'todo'
        @doc.visit '/puppetmaster/frames'
        frame = @doc.find(:css, 'iframe[id]:not([name])')

        @doc.within_frame(frame) do
          sleep 1
          expect(@doc.driver.frame_url).to match %r{/puppetmaster/get_cookie$}
        end
      end

      it 'waits for the frame to load' do
        skip 'todo'
        @doc.visit '/'

        @doc.execute_script <<~JS
          document.body.innerHTML += '<iframe src="/puppetmaster/slow" name="frame">'
        JS

        @doc.within_frame 'frame' do
          expect(@doc.driver.frame_url).to match %r{/puppetmaster/slow$}
          expect(@doc.html).to include('slow page')
        end

        expect(@doc.current_path).to eq('/')
      end

      it 'waits for the cross-domain frame to load' do
        skip 'todo'
        @doc.visit '/puppetmaster/frames'
        expect(@doc.current_path).to eq('/puppetmaster/frames')

        @doc.within_frame 'frame' do
          expect(@doc.driver.frame_url).to match %r{/puppetmaster/slow$}
          expect(@doc.body).to include('slow page')
        end

        expect(@doc.current_path).to eq('/puppetmaster/frames')
      end

      context 'with src == about:blank' do
        it "doesn't hang if no document created" do
          skip 'todo'
          @doc.visit '/'
          @doc.execute_script <<~JS
            document.body.insertAdjacentHTML("beforeend", '<iframe src="about:blank" name="frame">')
          JS
          @doc.within_frame 'frame' do
            expect(@doc).to have_no_xpath('/html/body/*')
          end
        end

        it "doesn't hang if built by JS" do
          skip 'todo'
          @doc.visit '/'
          @doc.execute_script <<~JS
            document.body.insertAdjacentHTML("beforeend", '<iframe src="about:blank" name="frame">');
            var iframeDocument = document.querySelector('iframe[name="frame"]').contentWindow.document;
            var content = '<html><body><p>Hello Frame</p></body></html>';
            iframeDocument.open('text/html', 'replace');
            iframeDocument.write(content);
            iframeDocument.close();
          JS

          @doc.within_frame 'frame' do
            expect(@doc).to have_content('Hello Frame')
          end
        end
      end

      context 'with no src attribute' do
        it "doesn't hang if the srcdoc attribute is used" do
          skip 'todo'
          @doc.visit '/'
          @doc.execute_script <<~JS
            document.body.insertAdjacentHTML("beforeend", '<iframe srcdoc="<p>Hello Frame</p>" name="frame">')
          JS

          @doc.within_frame 'frame' do
            expect(@doc).to have_content('Hello Frame', wait: false)
          end
        end

        it "doesn't hang if the frame is filled by JS" do
          skip 'todo'
          @doc.visit '/'

          @doc.execute_script <<~JS
            document.body.insertAdjacentHTML("beforeend", '<iframe id="frame" name="frame">')
          JS

          @doc.execute_script <<~JS
            var iframeDocument = document.querySelector('#frame').contentWindow.document;
            var content = '<html><body><p>Hello Frame</p></body></html>';
            iframeDocument.open('text/html', 'replace');
            iframeDocument.write(content);
            iframeDocument.close();
          JS

          @doc.within_frame 'frame' do
            expect(@doc).to have_content('Hello Frame', wait: false)
          end
        end
      end

      it 'supports clicking in a frame' do
        skip 'todo'
        @doc.visit '/'

        @doc.execute_script <<~JS
          document.body.insertAdjacentHTML("beforeend", '<iframe src="/puppetmaster/click_test" name="frame">')
        JS

        @doc.within_frame 'frame' do
          log = @doc.find(:css, '#log', wait: 2)
          one = @doc.find(:css, '#one')
          one.click
          sleep 5
          expect(log.text).to eq('one')
        end
      end

      it 'supports clicking in a frame with padding' do
        skip 'todo'
        @doc.visit '/'

        @doc.execute_script <<~JS
          document.body.insertAdjacentHTML("beforeend", '<iframe src="/puppetmaster/click_test" name="padded_frame" style="padding:100px;">')
        JS

        @doc.within_frame 'padded_frame' do
          log = @doc.find(:css, '#log')
          @doc.find(:css, '#one').click
          expect(log.text).to eq('one')
        end
      end

      it 'supports clicking in a frame nested in a frame' do
        skip 'todo'
        @doc.visit '/'

        # The padding on the frame here is to differ the sizes of the two
        # frames, ensuring that their offsets are being calculated seperately.
        # This avoids a false positive where the same frame's offset is
        # calculated twice, but the click still works because both frames had
        # the same offset.
        @doc.execute_script <<~JS
          document.body.insertAdjacentHTML("beforeend", '<iframe src="/puppetmaster/nested_frame_test" name="outer_frame" style="padding:200px">')
        JS

        @doc.within_frame 'outer_frame' do
          @doc.within_frame 'inner_frame' do
            log = @doc.find(:css, '#log')
            @doc.find(:css, '#one').click
            expect(log.text).to eq('one')
          end
        end
      end

      it 'does not wait forever for the frame to load' do
        skip 'todo'
        @doc.visit '/'

        expect do
          @doc.within_frame('omg') {}
        end.to(raise_error do |e|
          expect(e).to be_a(Isomorfeus::Puppetmaster::FrameNotFound).or be_a(Capybara::ElementNotFound)
        end)
      end
    end

    it 'handles obsolete node during an attach_file' do
      skip 'todo'
      @doc.visit '/puppetmaster/attach_file'
      @doc.attach_file 'file', __FILE__
    end

    it 'throws an error on an invalid CSS selector' do
      @doc.visit '/puppetmaster/table'
      expect { @doc.find('table tr:last') }.to raise_error(Isomorfeus::Puppetmaster::DOMException)
      expect { @doc.find('table').find('tr:last') }.to raise_error(Isomorfeus::Puppetmaster::DOMException)
    end

    it 'throws an error on invalid xpath' do
      @doc.visit('/puppetmaster/with_js')
      expect { @doc.find_xpath('#remove_me') }.to raise_error(Isomorfeus::Puppetmaster::DOMException)
      expect { @doc.find_xpath('.//body').find('.//#remove_me') }.to raise_error(Isomorfeus::Puppetmaster::DOMException)
    end

    it 'should submit form' do
      @doc.visit('/puppetmaster/send_keys')
      @doc.find('#without_submit_button').dispatch_event('submit')
      expect(@doc.find('#without_submit_button input').value).to eq('Submitted')
    end

    context 'whitespace tests' do
      before do
        @doc.visit '/puppetmaster/filter_text_test'
      end

      it 'gets text' do
        expect(@doc.find('#foo').visible_text).to eq 'foo'
      end

      it 'gets text stripped whitespace' do
        expect(@doc.find('#bar').visible_text).to eq 'bar'
      end

      it 'gets text and retains relevant nbsp and whistpace' do
        skip 'todo for jsdom' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#baz').visible_text).to eq ' baz    '
      end

      it 'gets text and retains releveant nbsp and unicode whitespace' do
        skip 'todo for jsdom' if Isomorfeus::Puppetmaster.driver == :jsdom
        expect(@doc.find('#qux').visible_text).to eq '  　 qux 　  '
      end
    end

    context 'supports accessing element properties' do
      before do
        @doc.visit '/puppetmaster/attributes_properties'
      end

      it 'gets innerHTML' do
        expect(@doc.find('.some_other_class').inner_html).to eq '<p>foobar</p>'
      end

      it 'gets outerHTML' do
        expect(@doc.find('.some_other_class').html).to eq '<div class="some_other_class"><p>foobar</p></div>'
      end

      it 'gets non existent property' do
        expect(@doc.find('.some_other_class').get_property('does_not_exist')).to eq nil
      end
    end

    it 'allows access to element attributes' do
      @doc.visit '/puppetmaster/attributes_properties'
      @doc.find('#my_link')
      e = @doc.find('#my_link')
      expect({ 'href' => e[:href], 'id' => e[:id], 'class' => e[:class], 'data' => e[:data] }).to eq(
        'href' => '#', 'id' => 'my_link', 'class' => 'some_class', 'data' => 'rah!'
      )
    end

    context 'SVG tests' do
      before do
        @doc.visit '/puppetmaster/svg_test'
      end

      it 'gets text from tspan node' do
        expect(@doc.find('tspan').visible_text).to eq 'svg foo'
      end
    end

    # setting require: [:modals] here sets the retry time to 1 second
    context 'modals', requires: [:modals] do
      before do
        @doc.visit '/puppetmaster/with_js'
      end

      it 'matches on partial strings' do
        skip 'todo'
        expect do
          @doc.accept_confirm '[reg.exp] (chara©+er$)' do
            @doc.find_by_content('Open for match').click
          end
        end.not_to raise_error
        expect(@doc).to have_xpath("//a[@id='open-match' and @confirmed='true']")
      end

      it 'matches on regular expressions' do
        skip 'todo'
        expect do
          @doc.accept_confirm(/^.t.ext.*\[\w{3}\.\w{3}\]/i) do
            @doc.find_by_content('Open for match').click
          end
        end.not_to raise_error
        expect(@doc).to have_xpath("//a[@id='open-match' and @confirmed='true']")
      end

      it 'works with nested modals' do
        skip 'todo'
        expect do
          @doc.dismiss_confirm 'Are you really sure?' do
            @doc.accept_confirm 'Are you sure?' do
              @doc.find_by_content('Open check twice').click
            end
          end
        end.not_to raise_error
        expect(@doc).to have_xpath("//a[@id='open-twice' and @confirmed='false']")
      end
    end

    context 'in threadsafe mode' do
      before do
        skip 'No threadsafe mode in this version'
        Isomorfeus::Puppetmaster::SpecHelper.reset_threadsafe(true, @doc) if Capybara.respond_to?(:threadsafe)
      end

      after do
        skip 'No threadsafe mode in this version'
        Isomorfeus::Puppetmaster::SpecHelper.reset_threadsafe(false, @doc) if Capybara.respond_to?(:threadsafe)
      end

      it 'uses per session wait setting' do
        skip 'No threadsafe mode in this version'
        Capybara.default_max_wait_time = 1
        @doc.config.default_max_wait_time = 2
        expect(@doc.driver.send(:session_wait_time)).to eq 2
      end
    end
  end
end
