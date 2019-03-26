module Isomorfeus
  module Puppetmaster
    class Puppeteer
      VIEWPORT_DEFAULT_WIDTH = 1024
      VIEWPORT_DEFAULT_HEIGHT = 768
      VIEWPORT_MAX_WIDTH = 1366
      VIEWPORT_MAX_HEIGHT = 768
      TIMEOUT = 30 # seconds
      REACTION_TIMEOUT = 0.5
      EVENTS = {
        blur: ['FocusEvent', {}],
        focus: ['FocusEvent', {}],
        focusin: ['FocusEvent', { bubbles: true  }],
        focusout: ['FocusEvent', { bubbles: true }],
        click: ['MouseEvent', { bubbles: true, cancelable: true }],
        dblckick: ['MouseEvent', { bubbles: true, cancelable: true }],
        mousedown: ['MouseEvent', { bubbles: true, cancelable: true }],
        mouseup: ['MouseEvent', { bubbles: true, cancelable: true }],
        mouseenter: ['MouseEvent', {}],
        mouseleave: ['MouseEvent', {}],
        mousemove: ['MouseEvent', { bubbles: true, cancelable: true }],
        mouseover: ['MouseEvent', { bubbles: true, cancelable: true }],
        mouseout: ['MouseEvent', { bubbles: true, cancelable: true }],
        context_menu: ['MouseEvent', { bubble: true, cancelable: true }],
        submit: ['Event', { bubbles: true, cancelable: true }],
        change: ['Event', { bubbles: true, cacnelable: false }],
        input: ['InputEvent', { bubbles: true, cacnelable: false }],
        wheel: ['WheelEvent', { bubbles: true, cancelable: true }]
      }.freeze

      attr_accessor :app, :default_document, :url_blacklist

      def initialize(options = {})
        # https://pptr.dev/#?product=Puppeteer&version=v1.12.2&show=api-puppeteerlaunchoptions
        # init ExecJs context
        @app = options.delete(:app)
        @options = options.dup
        @browser_type = @options.delete(:browser_type) { :chromium }
        @max_width = @options.delete(:max_width) { VIEWPORT_MAX_WIDTH }
        @max_height = @options.delete(:max_height) { VIEWPORT_MAX_HEIGHT }
        @width = @options.delete(:width) { VIEWPORT_DEFAULT_WIDTH > @max_width ? @max_width : VIEWPORT_DEFAULT_WIDTH }
        @height = @options.delete(:height) { VIEWPORT_DEFAULT_HEIGHT > @max_height ? @max_height : VIEWPORT_DEFAULT_HEIGHT }
        @timeout = @options.delete(:timeout) { TIMEOUT }
        @max_wait = @options.delete(:max_wait) { @timeout + 1 }
        @reaction_timeout = @options.delete(:reaction_timeout) { REACTION_TIMEOUT }
        @puppeteer_timeout = @timeout * 1000
        @puppeteer_reaction_timeout = @reaction_timeout * 1000
        @url_blacklist = @options.delete(:url_blacklist) { [] }
        @context = ExecJS.permissive_compile(puppeteer_launch)
        page_handle = await_result
        @default_document = Isomorfeus::Puppetmaster::Document.new(self, page_handle, Isomorfeus::Puppetmaster::Response.new('status' => 200))
        ObjectSpace.define_finalizer(self, self.class.close_browser(self))
      end

      def self.document_handle_disposer(driver, handle)
        cjs = <<~JAVASCRIPT
          if (AllPageHandles[#{handle}]) { AllPageHandles[#{handle}].close(); }
          delete AllPageHandles[#{handle}];
          delete ConsoleMessages[#{handle}];
        JAVASCRIPT
        proc { driver.execute_script(cjs) }
      end

      def self.node_handle_disposer(driver, handle)
        cjs = <<~JAVASCRIPT
          if (AllElementHandles[#{handle}]) { AllElementHandles[#{handle}].dispose(); }
          delete AllElementHandles[#{handle}];
        JAVASCRIPT
        proc { driver.execute_script(cjs) }
      end

      def browser
        await('LastResult = await CurrentBrowser.userAgent();')
      end

      def document_handles
        await <<~JAVASCRIPT
          var pages = await CurrentBrowser.pages();
          var handles = [];
          for (i=0; i< pages.length; i++) {
            handles.push(RegisterPage(pages[i]));
          }
          LastResult = handles;
        JAVASCRIPT
      end

      def document_accept_alert(document, **options, &block)
        # TODO maybe wrap in mutex
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllPageHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllPageHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_accept_confirm(document, **options, &block)
        # TODO maybe wrap in mutex
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllPageHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllPageHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_accept_leave_page(document, **options, &block)
        # TODO maybe wrap in mutex
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllPageHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllPageHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_accept_prompt(document, **options, &block)
        # TODO maybe wrap in mutex
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllPageHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllPageHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_all_text(document)
        await("LastResult = AllPageHandles[#{document.handle}].evaluate(function(){ return document.documentElement.textContent; });")
      end

      def document_body(document)
        node_data = await <<~JAVASCRIPT
          var element_handle = await AllPageHandles[#{document.handle}].$('body');
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
              var tag = node.tagName.toLowerCase();
              return [tag, null, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = 'body'
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_bring_to_front(document)
        await("await AllPageHandles[#{document.handle}].bringToFront();")
      end

      def document_clear_authentication_credentials(document)
        await("AllPageHandles[#{document.handle}].authenticate(null);")
      end

      def document_clear_cookies(document)
        await <<~JAVASCRIPT
          var cookies = await AllPageHandles[#{document.handle}].cookies();
          cookies.forEach(async(cookie) => {await AllPageHandles[#{document.handle}].deleteCookie(cookie);});
        JAVASCRIPT
      end

      def document_clear_extra_headers(document)
        await ("AllPageHandles[#{document.handle}].setExtraHTTPHeaders({});")
      end

      def document_clear_url_blacklist(document)
        await <<~JAVASCRIPT
          if (!(BrowserType === 'firefox')) {
            var cdp_session = await AllPageHandles[#{document.handle}].target().createCDPSession();
            await cdp_session.send('Network.setBlockedURLs', {urls: []});
            await cdp_session.detach();
          }
        JAVASCRIPT
      end

      def document_click(document, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # await "await  AllPageHandles[#{document.handle}].mouse.click(#{x},#{y},{button: 'left'});"
        # raise Isomorfeus::Pupppetmaster::InvalidActionError.new(:click) unless visible?
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var response_event_occurred = false;
          var response_handler = function(event){ response_event_occurred = true; };
          var response_watcher = new Promise(function(resolve, reject){
            setTimeout(function(){
              if (!response_event_occurred) { resolve(true); } 
              else { setTimeout(function(){ resolve(true); }, #{@puppeteer_timeout}); }
              AllPageHandles[#{document.handle}].removeListener('response', response_handler);
            }, #{@puppeteer_reaction_timeout});
          });
          AllPageHandles[#{document.handle}].on('response', response_handler);
          var navigation_watcher;
          if (BrowserType === 'firefox') {
            navigation_watcher = AllPageHandles[#{document.handle}].waitFor(1000);
          } else {
            navigation_watcher = AllPageHandles[#{document.handle}].waitForNavigation();
          }
          await AllPageHandles[#{document.handle}].evaluate(function(){ 
            var options = {button: 0, bubbles: true, cancelable: true};
            var node = window;
            var x = #{x ? x : 'null'};
            var y = #{y ? y : 'null'};
            var modifiers = #{modifiers};
            if (x && y) {
              options['clientX'] = x;
              options['clientY'] = y;
              var n = document.elementFromPoint(x, y);
              if (n) { node = n };
            }  
            if (modifiers.includes('meta')) { options['metaKey'] = true; }
            if (modifiers.includes('control')) { options['ctrlKey'] = true; }
            if (modifiers.includes('shift')) { options['shiftKey'] = true; }
            if (modifiers.includes('alt')) { options['altKey'] = true; }
            node.dispatchEvent(new MouseEvent('mousedown', options));
            node.dispatchEvent(new MouseEvent('mouseup', options));
            node.dispatchEvent(new MouseEvent('click', options));
          });
          await Promise.race([response_watcher, navigation_watcher]);
        JAVASCRIPT
      end

      def document_close(document)
        await <<~JAVASCRIPT
          await AllPageHandles[#{document.handle}].close();
          delete AllPageHandles[#{document.handle}];
          delete ConsoleMessages[#{document.handle}];
        JAVASCRIPT
      end

      def document_console(document)
        messages = @context.exec "return ConsoleMessages[#{document.handle}]"
        messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
      end

      def document_cookies(document)
        result = await("LastResult = await AllPageHandles[#{document.handle}].cookies();")
        result.to_h { |cookie| [cookie['name'], Isomorfeus::Puppetmaster::Cookie.new(cookie)] }
      end

      def document_dismiss_confirm(document, **options, &block)
        # TODO
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllPageHandles[#{document.handle}].on('dialog', DialogDismissHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllPageHandles[#{document.handle}].removeListener('dialog', DialogDismissHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::ModalNotFound if options.has_key?(:text) && !matched
      end

      def document_dismiss_leave_page(document, **options, &block)
        # TODO
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllPageHandles[#{document.handle}].on('dialog', DialogDismissHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllPageHandles[#{document.handle}].removeListener('dialog', DialogDismissHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::ModalNotFound if options.has_key?(:text) && !matched
      end

      def document_dismiss_prompt(document, **options, &block)
        # TODO
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllPageHandles[#{document.handle}].on('dialog', DialogDismissHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllPageHandles[#{document.handle}].removeListener('dialog', DialogDismissHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::ModalNotFound if options.has_key?(:text) && !matched
      end

      def document_dispatch_event(document, name, event_type = nil, **options)
        raise ArgumentError, 'Unknown event' unless EVENTS.key?(name.to_sym) || event_type
        event_type, opts = *EVENTS[name.to_s.downcase.tr('_', '').to_sym] if event_type.nil?
        opts.merge!(options)
        await <<~JAVASCRIPT
          handle = await AllPageHandles[#{document.handle}].evaluate(function(node){
            var event = new #{event_type}('#{name}'#{opts.empty? ? '' : opts});
            document.dispatchEvent(event);
          });
        JAVASCRIPT
      end

      def document_double_click(document, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var response_event_occurred = false;
          var response_handler = function(event){ response_event_occurred = true; };
          var response_watcher = new Promise(function(resolve, reject){
            setTimeout(function(){
              if (!response_event_occurred) { resolve(true); } 
              else { setTimeout(function(){ resolve(true); }, #{@puppeteer_timeout}); }
              AllPageHandles[#{document.handle}].removeListener('response', response_handler);
            }, #{@puppeteer_reaction_timeout});
          });
          AllPageHandlers[#{document.handle}].on('response', response_handler);
          var navigation_watcher;
          if (BrowserType === 'firefox') {
            navigation_watcher = AllPageHandles[#{document.handle}].waitFor(1000);
          } else {
            navigation_watcher = AllPageHandles[#{document.handle}].waitForNavigation();
          }
          await AllPageHandles[#{document.handle}].evaluate(function(){
            var options = {button: 0, bubbles: true, cancelable: true};
            var node = window;
            var x = #{x ? x : 'null'};
            var y = #{y ? y : 'null'};
            var modifiers = #{modifiers};
            if (x && y) {
              options['clientX'] = x;
              options['clientY'] = y;
              var n = document.elementFromPoint(x, y);
              if (n) { node = n };
            }
            if (modifiers.includes('meta')) { options['metaKey'] = true; }
            if (modifiers.includes('control')) { options['ctrlKey'] = true; }
            if (modifiers.includes('shift')) { options['shiftKey'] = true; }
            if (modifiers.includes('alt')) { options['altKey'] = true; }
            node.dispatchEvent(new MouseEvent('mousedown', options));
            node.dispatchEvent(new MouseEvent('mouseup', options));
            node.dispatchEvent(new MouseEvent('dblclick', options));
          });
          await Promise.race([response_watcher, navigation_watcher]);
        JAVASCRIPT
      end

      def document_evaluate_script(document, script, *args)
        await <<~JAVASCRIPT
          LastResult = await AllPageHandles[#{document.handle}].evaluate((arguments) => {
            return #{script} 
          }, #{args});
        JAVASCRIPT
      end

      def document_execute_script(document, script, *args)
        await <<~JAVASCRIPT
          LastResult = await AllPageHandles[#{document.handle}].evaluate((arguments) => {
            #{script} 
          }, #{args});
        JAVASCRIPT
      end

      def document_find(document, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle = await AllPageHandles[#{document.handle}].$("#{js_escaped_selector}");
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllPageHandles[#{document.handle}].evaluate((node) => {
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(selector)
        end
      end

      def document_find_all(document, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = await <<~JAVASCRIPT
          var node_data_array = [];
          var element_handle_array = await AllPageHandles[#{document.handle}].$$("#{js_escaped_selector}");
          if (element_handle_array) {
            for (var i=0; i<element_handle_array.length; i++) {
              var node_handle = RegisterElementHandle(element_handle_array[i]);
              var tt = await AllPageHandles[#{document.handle}].evaluate((node) => {
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              node_data_array.push({handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]});
            }  
          }
          LastResult = node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_find_all_xpath(document, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = await <<~JAVASCRIPT
          var node_data_array = [];
          var element_handle_array = await AllPageHandles[#{document.handle}].$x("#{js_escaped_query}");
          if (element_handle_array) {  
            for (var i=0; i<element_handle_array.length; i++) {
              var node_handle = RegisterElementHandle(element_handle_array[i]);
              var tt = await AllPageHandles[#{document.handle}].evaluate((node) => {
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              node_data_array.push({handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]});
            }
          }
          LastResult = node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_find_xpath(document, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle_array = await AllPageHandles[#{document.handle}].$x("#{js_escaped_query}");
          var element_handle = (element_handle_array) ? element_handle_array[0] : null;
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllPageHandles[#{document.handle}].evaluate((node) => {
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(query)
        end
      end

      def document_go_back(document)
        response_hash, messages = await <<~JAVASCRIPT
          ConsoleMessages[#{document.handle}] = [];
          var response = await AllPageHandles[#{document.handle}].goBack();
          if (response) {
            var request = response.request();
            var formatted_response = {
              headers: response.headers(),
              ok: response.ok(),
              remote_address: response.remoteAddress(),
              request: {
                failure: request.failure(),
                headers: request.headers(),
                method: request.method(),
                post_data: request.postData(),
                resource_type: request.resourceType(),
                url: request.url()
              },
              status: response.status(),
              status_text: response.statusText(),
              text: response.text(),
              url: response.url()
            };
            LastResult = [formatted_response, ConsoleMessages[#{document.handle}]];
          } else {
            LastResult = [null, ConsoleMessages[#{document.handle}]];
          }
        JAVASCRIPT
        con_messages = messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
        con_messages.each { |m| raise determine_error(m.text) if m.level == 'error' && !m.text.start_with?('Failed to load resource:') }
        if response_hash
          response = Isomorfeus::Puppetmaster::Response.new(response_hash)
          document.instance_variable_set(:@response, response)
        end
        document.response
      end

      def document_go_forward(document)
        response_hash, messages = await <<~JAVASCRIPT
          ConsoleMessages[#{document.handle}] = [];
          var response = await AllPageHandles[#{document.handle}].goForward();
          if (response) {
            var request = response.request();
            var formatted_response = {
              headers: response.headers(),
              ok: response.ok(),
              remote_address: response.remoteAddress(),
              request: {
                failure: request.failure(),
                headers: request.headers(),
                method: request.method(),
                post_data: request.postData(),
                resource_type: request.resourceType(),
                url: request.url()
              },
              status: response.status(),
              status_text: response.statusText(),
              text: response.text(),
              url: response.url()
            };
            LastResult = [formatted_response, ConsoleMessages[#{document.handle}]];
          } else {
            LastResult = [null, ConsoleMessages[#{document.handle}]];
          }
        JAVASCRIPT
        con_messages = messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
        con_messages.each { |m| raise determine_error(m.text) if m.level == 'error' && !m.text.start_with?('Failed to load resource:') }
        if response_hash
          response = Isomorfeus::Puppetmaster::Response.new(response_hash)
          document.instance_variable_set(:@response, response)
        end
        document.response
      end

      def document_goto(document, uri)
        parsed_uri = URI.parse(uri)
        parsed_uri.host = @app.host unless parsed_uri.host
        parsed_uri.port = @app.port unless parsed_uri.port
        parsed_uri.scheme = @app.scheme unless parsed_uri.scheme
        response_hash, messages = await <<~JAVASCRIPT
          ConsoleMessages[#{document.handle}] = [];
          var response = await AllPageHandles[#{document.handle}].goto('#{parsed_uri.to_s}');
          if (response) {
            var request = response.request();
            var formatted_response = {
              headers: response.headers(),
              ok: response.ok(),
              remote_address: response.remoteAddress(),
              request: {
                failure: request.failure(),
                headers: request.headers(),
                method: request.method(),
                post_data: request.postData(),
                resource_type: request.resourceType(),
                url: request.url()
              },
              status: response.status(),
              status_text: response.statusText(),
              text: response.text(),
              url: response.url()
            };
            LastResult = [formatted_response, ConsoleMessages[#{document.handle}]];
          } else {
            LastResult = [null, ConsoleMessages[#{document.handle}]];
          }
        JAVASCRIPT
        con_messages = messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
        con_messages.each { |m| raise determine_error(m.text) if m.level == 'error' && !m.text.start_with?('Failed to load resource:') }
        if response_hash
          response = Isomorfeus::Puppetmaster::Response.new(response_hash)
          document.instance_variable_set(:@response, response)
        end
        document.response
      end

      def document_head(document)
        node_data = await <<~JAVASCRIPT
          var element_handle = await AllPageHandles[#{document.handle}].$('head');
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
              var tag = node.tagName.toLower();
              return [tag, null, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_html(document)
        await "LastResult = await AllPageHandles[#{document.handle}].content();"
      end

      def document_open_new_document(_document, uri = nil)
        if !uri || uri == 'about:blank'
          parsed_uri = 'about:blank'
        else
          parsed_uri = URI.parse(uri)
          parsed_uri.host = @app.host unless parsed_uri.host
          parsed_uri.port = @app.port unless parsed_uri.port
          parsed_uri.scheme = @app.scheme unless parsed_uri.scheme
        end
        handle, response_hash, messages = await <<~JAVASCRIPT
          var new_page = await CurrentBrowser.newPage();
          var url = '#{parsed_uri.to_s}';
          new_page.setDefaultTimeout(#{@puppeteer_timeout});
          await new_page.setViewport({width: #{@width}, height: #{@height}});
          if (!(BrowserType === 'firefox')) {
            var new_target = new_page.target();
            var cdp_session = await new_target.createCDPSession();
            await cdp_session.send('Page.setDownloadBehavior', {behavior: 'allow', downloadPath: '#{Isomorfeus::Puppetmaster.save_path}'});
            if (#{@url_blacklist}.length > 0) { await cdp_session.send('Network.setBlockedURLs', {urls: #{@url_blacklist}}); }
            await cdp_session.detach();
          }
          var page_handle = RegisterPage(new_page); 
          var result_response = null;
          if (url && url !== '') { 
            var response = await new_page.goto(url);
            if (response) {
              var request = response.request();
              result_response = {
                headers: response.headers(),
                ok: response.ok(),
                remote_address: response.remoteAddress(),
                request: {
                  failure: request.failure(),
                  headers: request.headers(),
                  method: request.method(),
                  post_data: request.postData(),
                  resource_type: request.resourceType(),
                  url: request.url()
                },
                status: response.status(),
                status_text: response.statusText(),
                text: response.text(),
                url: response.url()
              } 
            }
          };
          LastResult = [page_handle, result_response, ConsoleMessages[page_handle]];
        JAVASCRIPT
        con_messages = messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
        con_messages.each { |m| raise determine_error(m.text) if m.level == 'error' && !m.text.start_with?('Failed to load resource:') }
        Isomorfeus::Puppetmaster::Document.new(self, handle, Isomorfeus::Puppetmaster::Response.new(response_hash))
      end

      def document_reload(document)
        response_hash = await"LastResult = await AllPageHandles[#{document.handle}].reload();"
        Isomorfeus::Puppetmaster::Response.new(response_hash)
      end

      def document_remove_cookie(document, name)
        await "await AllPageHandles[#{document.handle}].deleteCookie({name: '#{name}'})"
      end

      def document_render_base64(document, **options)
        # todo
        # https://pptr.dev/#?product=Puppeteer&version=v1.12.2&show=api-pagescreenshotoptions
        final_options = ["encoding: 'base64'"]
        if options.has_key?(:format)
          options[:format] = 'jpeg' if options[:format].to_s.downcase == 'jpg'
          final_options << "type: '#{options.delete(:format).to_s.downcase}'"
        end
        final_options << "quality: #{options.delete(:quality)}" if options.has_key?(:quality)
        final_options << "fullPage: #{options.delete(:full)}" if options.has_key?(:full)
        options.each do |k,v|
          final_options << "#{k.to_s.camelize(:lower)}: #{v}"
        end
        await "LastResult = await AllPageHandles[#{document.handle}].screenshot({#{final_options.join(', ')}});"
      end

      def document_reset_user_agent(document)
        await <<~JAVASCRIPT
          var original_user_agent = await CurrentBrowser.userAgent();
          await AllPageHandles[#{document.handle}].setUserAgent(original_user_agent);
        JAVASCRIPT
      end

      def document_right_click(document, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # offset: { x: int, y: int }
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var response_event_occurred = false;
          var response_handler = function(event){ response_event_occurred = true; };
          var response_watcher = new Promise(function(resolve, reject){
            setTimeout(function(){
              if (!response_event_occurred) { resolve(true); } 
              else { setTimeout(function(){ resolve(true); }, #{@puppeteer_timeout}); }
              AllPageHandles[#{document.handle}].removeListener('response', response_handler);
            }, #{@puppeteer_reaction_timeout});
          });
          AllPageHandles[#{document.handle}].on('response', response_handler);
          var navigation_watcher;
          if (BrowserType === 'firefox') {
            navigation_watcher = AllPageHandles[#{document.handle}].waitFor(1000);
          } else {
            navigation_watcher = AllPageHandles[#{document.handle}].waitForNavigation();
          }
          await AllPageHandles[#{document.handle}].evaluate(function(){
            var options = {button: 2, bubbles: true, cancelable: true};
            var node = window;
            var x = #{x ? x : 'null'};
            var y = #{y ? y : 'null'};
            var modifiers = #{modifiers};
            if (x && y) {
              options['clientX'] = x;
              options['clientY'] = y;
              var n = document.elementFromPoint(x, y);
              if (n) { node = n };
            }
            if (modifiers.includes('meta')) { options['metaKey'] = true; }
            if (modifiers.includes('control')) { options['ctrlKey'] = true; }
            if (modifiers.includes('shift')) { options['shiftKey'] = true; }
            if (modifiers.includes('alt')) { options['altKey'] = true; }
            node.dispatchEvent(new MouseEvent('mousedown', options));
            node.dispatchEvent(new MouseEvent('mouseup', options));
            node.dispatchEvent(new MouseEvent('contextmenu', options));
          });
          await Promise.race([response_watcher, navigation_watcher]);
        JAVASCRIPT
      end

      def document_save_pdf(document, path, **options)
        # todo
        # https://pptr.dev/#?product=Puppeteer&version=v1.12.2&show=api-pagepdfoptions
        absolute_path = File.absolute_path(path)
        final_options = ["path: '#{absolute_path}'"]
        final_options << "format: '#{options.delete(:format)}'" if options.has_key?(:format)
        final_options << "headerTemplate: `#{options.delete(:header_template)}`" if options.has_key?(:header_template)
        final_options << "footerTemplate: `#{options.delete(:footer_template)}`" if options.has_key?(:footer_template)
        final_options << "pageRanges: '#{options.delete(:page_ranges)}'" if options.has_key?(:page_ranges)
        final_options << "width: '#{options.delete(:width)}'" if options.has_key?(:width)
        final_options << "height: '#{options.delete(:height)}'" if options.has_key?(:height)
        options.each do |k,v|
          final_options << "#{k.to_s.camelize(:lower)}: #{v}"
        end
        await "await AllPageHandles[#{document.handle}].pdf({#{final_options.join(', ')}});"
      end

      def document_save_screenshot(document, path, **options)
        # todo
        # https://pptr.dev/#?product=Puppeteer&version=v1.12.2&show=api-pagescreenshotoptions
        absolute_path = File.absolute_path(path)
        final_options = ["path: '#{absolute_path}'"]
        if options.has_key?(:format)
          options[:format] = 'jpeg' if options[:format].to_s.downcase == 'jpg'
          final_options << "type: '#{options.delete(:format).to_s.downcase}'"
        end
        final_options << "quality: #{options.delete(:quality)}" if options.has_key?(:quality)
        final_options << "fullPage: #{options.delete(:full)}" if options.has_key?(:full)
        options.each do |k,v|
          final_options << "#{k.to_s.camelize(:lower)}: #{v}"
        end
        await "await AllPageHandles[#{document.handle}].screenshot({#{final_options.join(', ')}});"
      end

      def document_scroll_by(document, x, y)
        await "await AllPageHandles[#{document.handle}].evaluate('window.scrollBy(#{x}, #{y})');"
      end

      def document_scroll_to(document, x, y)
        await "await AllPageHandles[#{document.handle}].evaluate('window.scrollTo(#{x}, #{y})');"
      end

      def document_set_authentication_credentials(document, username, password)
        await "await AllPageHandles[#{document.handle}].authenticate({username: '#{username}', password: '#{password}'});"
      end

      def document_set_cookie(document, name, value, **options)
        options[:name]  ||= name
        options[:value] ||= value
        uri = document_url(document)
        if uri == 'about:blank'
          uri = if Isomorfeus::Puppetmaster.server_host
                  u = URI.new
                  u.scheme = Isomorfeus::Puppetmaster.server_scheme if Isomorfeus::Puppetmaster.server_scheme
                  u.host = Isomorfeus::Puppetmaster.server_host
                  u.to_s
                else
                  'http://127.0.0.1'
                end
        end
        options[:domain] ||= URI.parse(uri).host
        final_options = []
        final_options << "expires: #{options.delete(:expires).to_i}" if options.has_key?(:expires)
        final_options << "httpOnly: #{options.delete(:http_only)}" if options.has_key?(:http_only)
        final_options << "secure: #{options.delete(:secure)}" if options.has_key?(:secure)
        final_options << "sameSite: '#{options.delete(:same_site)}'" if options.has_key?(:same_site)
        options.each do |k,v|
          final_options << "#{k}: '#{v}'"
        end
        await "await AllPageHandles[#{document.handle}].setCookie({#{final_options.join(', ')}});"
      end

      def document_set_extra_headers(document, headers_hash)
        await "await AllPageHandles[#{document.handle}].setExtraHTTPHeaders({#{headers_hash.map { |k, v| "'#{k}': '#{v}'" }.join(', ')}});"
      end

      def document_set_url_blacklist(document, url_array)
        # https://www.chromium.org/administrators/url-blacklist-filter-format
        @url_blacklist = url_array
        await <<~JAVASCRIPT
          if (!(BrowserType === 'firefox')) {
            var cdp_session = await AllPageHandles[#{document.handle}].target().createCDPSession();
            await cdp_session.send('Network.setBlockedURLs', {urls: #{url_array}});
            await cdp_session.detach();
          }
        JAVASCRIPT
      end

      def document_set_user_agent(document, agent_string)
        await "await AllPageHandles[#{document.handle}].setUserAgent('#{agent_string}');"
      end

      def document_title(document)
        await "LastResult = await AllPageHandles[#{document.handle}].title();"
      end

      def document_type_keys(document, *keys)
        cjs = "await AllPageHandles[#{document.handle}].bringToFront();"
        top_modifiers = []
        keys.each do |key|
          if key.is_a?(String)
            key.each_char do |c|
              need_shift = /[[:upper:]]/.match(c)
              cjs << "await AllPageHandles[#{document.handle}].keyboard.down('Shift');\n" if need_shift
              c = "Key#{c.upcase}" if /[[:alpha:]]/.match(c)
              cjs << "await AllPageHandles[#{document.handle}].keyboard.down('#{c}');\n"
              cjs << "await AllPageHandles[#{document.handle}].keyboard.up('#{c}');\n"
              cjs << "await AllPageHandles[#{document.handle}].keyboard.up('Shift');\n" if need_shift
            end
          elsif key.is_a?(Symbol)
            if %i[ctrl Ctrl].include?(key)
              key = :control
            elsif  %i[command Command Meta].include?(key)
              key = :meta
            elsif  %i[divide Divide].include?(key)
              key = :numpad_divide
            elsif  %i[decimal Decimal].include?(key)
              key = :numpad_decimal
            elsif %i[left right up down].include?(key)
              key = "arrow_#{key}".to_sym
            end
            if %i[alt alt_left alt_right control control_left control_rigth meta meta_left meta_right shift shift_left shift_right].include?(key)
              top_modifiers << key
              cjs << "await AllPageHandles[#{document.handle}].keyboard.down('#{key.to_s.camelize}');\n"
            else
              cjs << "await AllPageHandles[#{document.handle}].keyboard.press('#{key.to_s.camelize}');\n"
            end
          elsif key.is_a?(Array)
            modifiers = []
            key.each do |k|
              if k.is_a?(Symbol)
                if %i[ctrl Ctrl].include?(k)
                  k = :control
                elsif  %i[command Command Meta].include?(k)
                  k = :meta
                elsif  %i[divide Divide].include?(k)
                  k = :numpad_divide
                elsif  %i[decimal Decimal].include?(k)
                  k = :numpad_decimal
                elsif %i[left right up down].include?(key)
                  k = "arrow_#{key}".to_sym
                end
                if %i[alt alt_left alt_right control control_left control_rigth meta meta_left meta_right shift shift_left shift_right].include?(k)
                  modifiers << k
                  cjs << "await AllPageHandles[#{document.handle}].keyboard.down('#{k.to_s.camelize}');\n"
                else
                  cjs << "await AllPageHandles[#{document.handle}].keyboard.press('#{k.to_s.camelize}');\n"
                end
              elsif k.is_a?(String)
                k.each_char do |c|
                  need_shift = /[[:upper:]]/.match(c)
                  cjs << "await AllPageHandles[#{document.handle}].keyboard.down('Shift');\n" if need_shift
                  c = "Key#{c.upcase}" if /[[:alpha:]]/.match(c)
                  cjs << "await AllPageHandles[#{document.handle}].keyboard.press('#{c}');\n"
                  cjs << "await AllPageHandles[#{document.handle}].keyboard.up('Shift');\n" if need_shift
                end
              end
            end
            modifiers.reverse.each do |k|
              cjs << "await AllPageHandles[#{document.handle}].keyboard.up('#{k.to_s.camelize}');\n"
            end
          end
        end
        top_modifiers.reverse.each do |key|
          cjs << "await AllPageHandles[#{document.handle}].keyboard.up('#{key.to_s.camelize}');\n"
        end
        await(cjs)
      end

      def document_url(document)
        await "LastResult = await AllPageHandles[#{document.handle}].evaluate('window.location.href');"
      end

      def document_user_agent(document)
        await "LastResult = await AllPageHandles[#{document.handle}].evaluate('window.navigator.userAgent');"
      end

      def document_viewport_maximize(document)
        document_viewport_resize(document, @max_width, @max_height)
      end

      def document_viewport_resize(document, width, height)
        width = @max_width if width > @max_width
        height = @max_height if width > @max_height
        await "await AllPageHandles[#{document.handle}].setViewport({width: #{width}, height: #{height}});"
      end

      def document_viewport_size(document)
        viewport = @context.eval "AllPageHandles[#{document.handle}].viewport()"
        [viewport['width'], viewport['height']]
      end

      def document_wait_for(document, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle = await AllPageHandles[#{document.handle}].waitForSelector("#{js_escaped_selector}");
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(selector)
        end
      end

      def document_wait_for_xpath(document, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle = await AllPageHandles[#{document.handle}].waitForXPath("#{js_escaped_query}");
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(selector)
        end
      end

      ##### frame

      def frame_all_text(frame)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            return frame.contentDocument.documentElement.textContent;
          }, AllElementHandles[#{frame.handle}]);
        JAVASCRIPT
      end

      def frame_body(frame)
        node_data = await <<~JAVASCRIPT
          var tt = await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            node = frame.contentDocument.body;
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            return [tag, type];
          }, AllElementHandles[#{frame.handle}]);
          LastResult = {handle: node_handle, tag: tt[0], type: tt[1]};
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = 'body'
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def frame_focus(frame)
        await <<~JAVASCRIPT
          await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            frame.contentDocument.documentElement.focus();
          }, AllElementHandles[#{frame.handle}]);
        JAVASCRIPT
      end

      def frame_head(frame)
        node_data = await <<~JAVASCRIPT
          var tt = await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            node = frame.contentDocument.head;
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            return [tag, type];
          }, AllElementHandles[#{frame.handle}]);
          LastResult = {handle: node_handle, tag: tt[0], type: tt[1]};
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = 'body'
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def frame_html(frame)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            return frame.contentDocument.documentElement.outerHTML;
          }, AllElementHandles[#{frame.handle}]);
        JAVASCRIPT
      end

      def frame_title(frame)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            return frame.contentDocument.title;
          }, AllElementHandles[#{frame.handle}]);
        JAVASCRIPT
      end

      def frame_url(frame)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            return frame.contentDocument.location.href;
          }, AllElementHandles[#{frame.handle}]);
        JAVASCRIPT
      end

      def frame_visible_text(frame)
        # if node is AREA, check visibility of relevant image
        text = await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{frame.handle}].executionContext().evaluate((frame) => {
            var node = frame.contentDocument.body;
            var temp_node = node;
            while (temp_node) {
              style = window.getComputedStyle(node);
              if (style.display === "none" || style.visibility === "hidden" || parseFloat(style.opacity) === 0) { return ''; }
              temp_node = temp_node.parentElement;
            }
            if (node.nodeName == "TEXTAREA" || node instanceof SVGElement) { return node.textContent; }
            else { return node.innerText; }
          }, AllElementHandles[#{frame.handle}]);
        JAVASCRIPT
        text.gsub(/\A[[:space:]&&[^\u00a0]]+/, "").gsub(/[[:space:]&&[^\u00a0]]+\z/, "").gsub(/\n+/, "\n").tr("\u00a0", " ")
      end

      ##### node

      def node_all_text(node)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){
            return node.textContent;
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_click(node, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # raise Isomorfeus::Pupppetmaster::InvalidActionError.new(:click) unless visible?
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var response_event_occurred = false;
          var response_handler = function(event){ response_event_occurred = true; };
          var response_watcher = new Promise(function(resolve, reject){
            setTimeout(function(){
              if (!response_event_occurred) { resolve(true); } 
              else { setTimeout(function(){ resolve(true); }, #{@puppeteer_timeout}); }
              AllPageHandles[#{node.document.handle}].removeListener('response', response_handler);
            }, #{@puppeteer_reaction_timeout});
          });
          AllPageHandles[#{node.document.handle}].on('response', response_handler);
          var navigation_watcher;
          if (BrowserType === 'firefox') {
            navigation_watcher = AllPageHandles[#{node.document.handle}].waitFor(1000);
          } else {
            navigation_watcher = AllPageHandles[#{node.document.handle}].waitForNavigation();
          }
          await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){ 
            var options = {button: 0, bubbles: true, cancelable: true};
            var x = #{x ? x : 'null'};
            var y = #{y ? y : 'null'};
            var modifiers = #{modifiers};
            if (x && y) {
              var bounding_box = node.getBoundingClientRect();
              options['clientX'] = bounding_box.x + x;
              options['clientY'] = bounding_box.y + y;
            }
            if (modifiers.includes('meta')) { options['metaKey'] = true; }
            if (modifiers.includes('control')) { options['ctrlKey'] = true; }
            if (modifiers.includes('shift')) { options['shiftKey'] = true; }
            if (modifiers.includes('alt')) { options['altKey'] = true; }
            node.dispatchEvent(new MouseEvent('mousedown', options));
            node.dispatchEvent(new MouseEvent('mouseup', options));
            node.dispatchEvent(new MouseEvent('click', options));
          }, AllElementHandles[#{node.handle}]);
          await Promise.race([response_watcher, navigation_watcher]);
        JAVASCRIPT
      end

      def node_disabled?(node)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(node => {
            const xpath = `parent::optgroup[@disabled] | ancestor::select[@disabled] | parent::fieldset[@disabled] |
                           ancestor::*[not(self::legend) or preceding-sibling::legend][parent::fieldset[@disabled]]`;
            return node.disabled || document.evaluate(xpath, node, null, XPathResult.BOOLEAN_TYPE, null).booleanValue;
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_dispatch_event(node, name, event_type = nil, **options)
        raise ArgumentError, 'Unknown event' unless EVENTS.key?(name.to_sym) || event_type
        event_type, opts = *EVENTS[name.to_sym] if event_type.nil?
        opts.merge!(options)
        final_options = options.map { |k,v| "#{k}: '#{v}'" }
        await <<~JAVASCRIPT
          await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){
            var event = new #{event_type}('#{name}', { #{final_options.join(', ')} });
            node.dispatchEvent(event);
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_double_click(node, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # offset: { x: int, y: int }
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var response_event_occurred = false;
          var response_handler = function(event){ response_event_occurred = true; };
          var response_watcher = new Promise(function(resolve, reject){
            setTimeout(function(){
              if (!response_event_occurred) { resolve(true); } 
              else { setTimeout(function(){ resolve(true); }, #{@puppeteer_timeout}); }
              AllPageHandles[#{node.document.handle}].removeListener('response', response_handler);
            }, #{@puppeteer_reaction_timeout});
          });
          AllPageHandles[#{node.document.handle}].on('response', response_handler);
          var navigation_watcher;
          if (BrowserType === 'firefox') {
            navigation_watcher = AllPageHandles[#{node.document.handle}].waitFor(1000);
          } else {
            navigation_watcher = AllPageHandles[#{node.document.handle}].waitForNavigation();
          }
          await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){
            var options = {button: 0, bubbles: true, cancelable: true};
            var x = #{x ? x : 'null'};
            var y = #{y ? y : 'null'};
            var modifiers = #{modifiers};
            if (x && y) {
              var bounding_box = node.getBoundingClientRect();
              options['clientX'] = bounding_box.left + x;
              options['clientY'] = bounding_box.top + y;
            }
            if (modifiers.includes('meta')) { options['metaKey'] = true; }
            if (modifiers.includes('control')) { options['ctrlKey'] = true; }
            if (modifiers.includes('shift')) { options['shiftKey'] = true; }
            if (modifiers.includes('alt')) { options['altKey'] = true; }
            node.dispatchEvent(new MouseEvent('mousedown', options));
            node.dispatchEvent(new MouseEvent('mouseup', options));
            node.dispatchEvent(new MouseEvent('dblclick', options));
            return options;
          }, AllElementHandles[#{node.handle}]);
          await Promise.race([response_watcher, navigation_watcher]);
        JAVASCRIPT
      end

      def node_drag_to(node, other_node)
        if node[:draggable]
          await <<~JAVASCRIPT
            await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node) {
              document.addEventListener('mousedown', event => {
                window.puppeteer_mousedown_prevented = event.defaultPrevented;
              }, { once: true, passive: true });
            }, AllElementHandles[#{node.handle}]);
          JAVASCRIPT
          # TODO use scrollIntoView once chromium bug is fixed
          # https://bugs.chromium.org/p/chromium/issues/detail?id=939740&can=2&start=0&num=100&q=mousemove%20scrollintoview&colspec=ID%20Type%20Status%20Priority%20Milestone%20Owner%20Summary&groupby=&sort=
          await <<~JAVASCRIPT
            var node_handle = #{node.handle};
            await AllElementHandles[node_handle].executionContext().evaluateHandle(function(node, other_node) {
              var n = node;
              var top = n.offsetTop, left = n.offsetLeft, width = n.offsetWidth, height = n.offsetHeight;          
              while(n.offsetParent) { n = n.offsetParent; top += n.offsetTop; left += n.offsetLeft; }
              var node_in_view = (top >= window.pageYOffset && left >= window.pageXOffset &&
                (top + height) <= (window.pageYOffset + window.innerHeight) && (left + width) <= (window.pageXOffset + window.innerWidth));
              if (!node_in_view) { node.scrollTo(0,0); };
              setTimeout(function(){
                var client_rect = node.getBoundingClientRect();
                var x = (client_rect.left + (client_rect.width / 2));
                var y = (client_rect.top + (client_rect.height / 2));
                node.dispatchEvent(new MouseEvent('mousemove', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                setTimeout(function(){
                  node.dispatchEvent(new MouseEvent('mousedown', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                  if (window.puppeteer_mousedown_prevented) {
                    n = other_node;
                    top = n.offsetTop; left = n.offsetLeft; width = n.offsetWidth; height = n.offsetHeight;          
                    while(n.offsetParent) { n = n.offsetParent; top += n.offsetTop; left += n.offsetLeft; }
                    var node_in_view = (top >= window.pageYOffset && left >= window.pageXOffset &&
                    (top + height) <= (window.pageYOffset + window.innerHeight) && (left + width) <= (window.pageXOffset + window.innerWidth));
                    if (!node_in_view) { other_node.scrollTo(0,0) };
                    setTimeout(function(){
                      client_rect = other_node.getBoundingClientRect();
                      x = (client_rect.left + (client_rect.width / 2));
                      y = (client_rect.top + (client_rect.height / 2));
                      node.dispatchEvent(new MouseEvent('mousemove', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                      setTimeout(function(){
                        node.dispatchEvent(new MouseEvent('mouseup', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                      }, #{@puppeteer_reaction_timeout/2});
                    }, #{@puppeteer_reaction_timeout});
                  } else {
                    var dt = new DataTransfer();
                    if (node.tagName == 'A'){ dt.setData('text/uri-list', node.href); dt.setData('text', node.href); }
                    if (node.tagName == 'IMG'){ dt.setData('text/uri-list', node.src); dt.setData('text', node.src); }
                    var opts = { cancelable: true, bubbles: true, dataTransfer: dt };
                    var dragEvent = new DragEvent('dragstart', opts);
                    node.dispatchEvent(dragEvent);
                    n = other_node;
                    top = n.offsetTop; left = n.offsetLeft; width = n.offsetWidth; height = n.offsetHeight;          
                    while(n.offsetParent) { n = n.offsetParent; top += n.offsetTop; left += n.offsetLeft; }
                    var node_in_view = (top >= window.pageYOffset && left >= window.pageXOffset &&
                    (top + height) <= (window.pageYOffset + window.innerHeight) && (left + width) <= (window.pageXOffset + window.innerWidth));
                    if (!node_in_view) { other_node.scrollTo(0,0); };
                    setTimeout(function(){
                      var rect = node.getBoundingClientRect()
                      var node_center = new DOMPoint((rect.left + rect.right)/2, (rect.top + rect.bottom)/2);
                      var other_rect = other_node.getBoundingClientRect();
                      var other_point = new DOMPoint((other_rect.left + other_rect.right)/2, (other_rect.top + other_rect.bottom)/2);
                      var entry_point = null;
                      var slope = (other_point.y - other_point.y) / (other_point.x - node_center.x);
                      if (other_point.x <= other_point.x) { // left side
                        var minXy = slope * (other_rect.left - node_center.x) + node_center.y;
                        if (other_rect.top <= minXy && minXy <= other_rect.bottom) { entry_point = new DOMPoint(other_rect.left, minXy); }
                      }
                      if (node_center.x >= other_point.x) { // right side
                        var maxXy = slope * (other_rect.right - node_center.x) + node_center.y;
                        if (other_rect.top <= maxXy && maxXy <= other_rect.bottom) { entry_point = new DOMPoint(other_rect.right, maxXy); }
                      }
                      if (node_center.y <= other_point.y) { // top side
                        var minYx = (other_point.top - node_center.y) / slope + node_center.x;
                        if (other_rect.left <= minYx && minYx <= other_rect.right) { entry_point = new DOMPoint(minYx, other_rect.top); }
                      }
                      if (node_center.y >= other_point.y) { // bottom side
                        var maxYx = (other_rect.bottom - node_center.y) / slope + node_center.x;
                        if (other_rect.left <= maxYx && maxYx <= other_rect.right) { entry_point = new DOMPoint(maxYx, other_rect.bottom); }
                      }
                      if (!entry_point) {
                        entry_point = new DOMPoint(node_center.x, node_center.y);
                      }
                      var drag_over_event = new DragEvent('dragover', {clientX: entry_point.x, clientY: entry_point.y, bubbles: true, cancelable: true});
                      other_node.dispatchEvent(drag_over_event);
                      var other_center = new DOMPoint((other_rect.left + other_rect.right)/2, (other_rect.top + other_rect.bottom)/2);
                      drag_over_event = new DragEvent('dragover', {clientX: targetCenter.x, clientY: targetCenter.y, bubbles: true, cancelable: true});
                      other_node.dispatchEvent(drag_over_event);
                      other_node.dispatchEvent(new DragEvent('dragleave', {bubbles: true, cancelable: true}));
                      if (drag_over_event.defaultPrevented) {
                        other_node.dispatchEvent(new DragEvent('drop', {bubbles: true, cancelable: true}));
                      }
                      node.dispatchEvent(new DragEvent('dragend', {bubbles: true, cancelable: true}));
                      client_rect = other_node.getBoundingClientRect();
                      x = (client_rect.left + (client_rect.width / 2));
                      y = (client_rect.top + (client_rect.height / 2));
                      node.dispatchEvent(new MouseEvent('mouseup', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                    }, #{@puppeteer_reaction_timeout});
                  }
                }, #{@puppeteer_reaction_timeout/2});
              }, #{@puppeteer_reaction_timeout});
            }, AllElementHandles[node_handle], AllElementHandles[#{other_node.handle}]);
          JAVASCRIPT
          sleep (@reaction_timeout * 3) + 0.2
        else
          await <<~JAVASCRIPT
            var node_handle = #{node.handle};
            await AllElementHandles[node_handle].executionContext().evaluateHandle(function(node, other_node) {
              var n = node;
              var top = n.offsetTop, left = n.offsetLeft, width = n.offsetWidth, height = n.offsetHeight;          
              while(n.offsetParent) { n = n.offsetParent; top += n.offsetTop; left += n.offsetLeft; }
              var node_in_view = (top >= window.pageYOffset && left >= window.pageXOffset &&
                (top + height) <= (window.pageYOffset + window.innerHeight) && (left + width) <= (window.pageXOffset + window.innerWidth));
              if (!node_in_view) { res = (n === node); node.scrollTo(0,0); };
              setTimeout(function() {
                var client_rect = node.getBoundingClientRect();
                var x = (client_rect.left + (client_rect.width / 2));
                var y = (client_rect.top + (client_rect.height / 2));
                node.dispatchEvent(new MouseEvent('mousemove', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                setTimeout(function() {
                  node.dispatchEvent(new MouseEvent('mousedown', {button: 0, buttons: 1, clientX: x, clientY: y, bubbles: true, cancelable: true}));
                  var n = other_node;
                  var top = n.offsetTop, left = n.offsetLeft, width = n.offsetWidth, height = n.offsetHeight;          
                  while(n.offsetParent) { n = n.offsetParent; top += n.offsetTop; left += n.offsetLeft; }
                  var other_node_in_view = (top >= window.pageYOffset && left >= window.pageXOffset &&
                    (top + height) <= (window.pageYOffset + window.innerHeight) && (left + width) <= (window.pageXOffset + window.innerWidth));
                  if (!other_node_in_view) { other_node.scrollTo(0,0); };
                  setTimeout(function() {
                    var other_client_rect = other_node.getBoundingClientRect();
                    var x = (other_client_rect.left + (other_client_rect.width / 2));
                    var y = (other_client_rect.top + (other_client_rect.height / 2));
                    node.dispatchEvent(new MouseEvent('mousemove', {button: 0, buttons: 1, clientX: x, clientY: y, bubbles: true, cancelable: true}));
                    setTimeout(function() {
                      node.dispatchEvent(new MouseEvent('mouseup', {button: 0, buttons: 1, clientX: x, clientY: y, bubbles: true, cancelable: true}));
                    }, #{@puppeteer_reaction_timeout/2});
                  }, #{@puppeteer_reaction_timeout});
                }, #{@puppeteer_reaction_timeout/2});
              }, #{@puppeteer_reaction_timeout});
            }, AllElementHandles[node_handle], AllElementHandles[#{other_node.handle}]);
          JAVASCRIPT
          sleep (@reaction_timeout * 3) + 0.2
        end
      end

      def node_equal(node, other_node)
        await <<~JAVASCRIPT
        var node_handle = #{node.handle};
        var other_handle = #{other_node.handle}; 
        if (AllElementHandles[node_handle] && AllElementHandles[other_handle]) {
          try {
            var handle = await AllElementHandles[node_handle].executionContext().evaluateHandle(function(node, other_node){
              return (node === other_node); 
            }, AllElementHandles[node_handle],AllElementHandles[other_handle]);
            LastResult = await handle.jsonValue();
          } catch (err) {
            LastResult = false;
          }
        }
        JAVASCRIPT
      end

      def node_execute_script(node, script, *args)
        await <<~JAVASCRIPT
          var node_handle = #{node.handle};
          await AllElementHandles[node_handle].executionContext().evaluateHandle((node, arguments) => {
            arguments.unshift(node);
            #{script}
          }, AllElementHandles[node_handle], #{args[1..-1]});
        JAVASCRIPT
      end

      def node_evaluate_script(node, script, *args)
        await <<~JAVASCRIPT
          var node_handle = #{node.handle};
          await AllElementHandles[node_handle].executionContext().evaluateHandle((node, arguments) => {
            arguments.unshift(node);
            return #{script};
          }, AllElementHandles[node_handle], #{args[1..-1]});
          LastResult = await handle.jsonValue();
        JAVASCRIPT
      end

      def node_find(node, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle = await AllElementHandles[#{node.handle}].$("#{js_escaped_selector}");
            if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(selector)
        end
      end

      def node_find_all(node, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = await <<~JAVASCRIPT
          var node_data_array = [];
          var element_handle_array = await AllElementHandles[#{node.handle}].$("#{js_escaped_selector}");
          if (element_handle_array) {
            
            for (var i=0; i<element_handle_array.length; i++) {
              var node_handle = RegisterElementHandle(element_handle_array[i]);
              var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              node_data_array.push({handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]});
            }
          }
          LastResult = node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        end
      end

      def node_find_all_xpath(node, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = await <<~JAVASCRIPT
          var node_data_array = [];
          var element_handle_array = await AllElementHandles[#{node.handle}].$x("#{js_escaped_query}");
          if (element_handle_array) {  
            for (var i=0; i<element_handle_array.length; i++) {
              var node_handle = RegisterElementHandle(element_handle_array[i]);
              var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              node_data_array.push({handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]});
            }  
          }
          LastResult = node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        end
      end

      def node_find_xpath(node, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle_array = await AllElementHandles[#{node.handle}].$x("#{js_escaped_query}");
          var element_handle = (element_handle_array) ? element_handle_array[0] : null;
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var tt = await AllElementHandles[node_handle].executionContext().evaluate((node) => {
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type, node.isContentEditable];
            }, AllElementHandles[node_handle]);
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1], content_editable: tt[2]};
          }
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(query)
        end
      end

      def node_focus(node)
        await "await AllElementHandles[#{node.handle}].focus();"
      end

      def node_get_attribute(node, attribute)
        attribute = attribute.to_s
        # if attribute == 'class'
          # attribute = 'className'
        if !(attribute.start_with?('aria-') || attribute.start_with?('data-'))
          attribute = attribute.camelize(:lower)
        end
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node, attribute){
            return node.getAttribute(attribute);
          }, AllElementHandles[#{node.handle}], '#{attribute}');
        JAVASCRIPT
      end

      def node_hover(node)
        await "await AllElementHandles[#{node.handle}].hover(); }"
      end

      def node_html(node)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){
            return node.outerHTML;
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_in_viewport?(node)
        await <<~JAVASCRIPT
          var node_handle = #{node.handle};
          var handle = await AllElementHandles[node_handle].executionContext().evaluateHandle(function(node) {
            var top = node.offsetTop, left = node.offsetLeft, width = node.offsetWidth, height = node.offsetHeight;
            while(node.offsetParent) { node = node.offsetParent; top += node.offsetTop; left += node.offsetLeft; }
            return (top >= window.pageYOffset && left >= window.pageXOffset &&
              (top + height) <= (window.pageYOffset + window.innerHeight) && (left + width) <= (window.pageXOffset + window.innerWidth));
          }, AllElementHandles[node_handle]);
          LastResult = await handle.jsonValue();
        JAVASCRIPT
      end

      def node_inner_html(node)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){
            return node.innerHTML;
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_render_base64(node, **options)
        # https://pptr.dev/#?product=Puppeteer&version=v1.12.2&show=api-pagescreenshotoptions
        final_options = ["encoding: 'base64'"]
        if options.has_key?(:format)
          options[:format] = 'jpeg' if options[:format].to_s.downcase == 'jpg'
          final_options << "type: '#{options.delete(:format).to_s.downcase}'"
        end
        final_options << "quality: #{options.delete(:quality)}" if options.has_key?(:quality)
        box = await "LastResult = await AllElementHandles[#{node.handle}].boundingBox();"
        final_options << "clip: {x: #{box['x']}, y: #{box['y']}, width: #{box['width']}, height: #{box['height']}}"
        options.each { |k,v| final_options << "#{k.to_s.camelize(:lower)}: #{v}" }
        await "LastResult = await AllPageHandles[#{node.document.handle}].screenshot({#{final_options.join(', ')}});"
      end

      def node_right_click(node, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # offset: { x: int, y: int }
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var response_event_occurred = false;
          var response_handler = function(event){ response_event_occurred = true; };
          var response_watcher = new Promise(function(resolve, reject){
            setTimeout(function(){
              if (!response_event_occurred) { resolve(true); } 
              else { setTimeout(function(){ resolve(true); }, #{@puppeteer_timeout}); }
              AllPageHandles[#{node.document.handle}].removeListener('response', response_handler);
            }, #{@puppeteer_reaction_timeout});
          });
          AllPageHandles[#{node.document.handle}].on('response', response_handler);
          var navigation_watcher;
          if (BrowserType === 'firefox') {
            navigation_watcher = AllPageHandles[#{node.document.handle}].waitFor(1000);
          } else {
            navigation_watcher = AllPageHandles[#{node.document.handle}].waitForNavigation();
          }
          await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){
            var options = {button: 2, bubbles: true, cancelable: true};
            var x = #{x ? x : 'null'};
            var y = #{y ? y : 'null'};
            var modifiers = #{modifiers};
            if (x && y) {
              var bounding_box = node.getBoundingClientRect();
              options['clientX'] = bounding_box.left + x;
              options['clientY'] = bounding_box.top + y;
            }
            if (modifiers.includes('meta')) { options['metaKey'] = true; }
            if (modifiers.includes('control')) { options['ctrlKey'] = true; }
            if (modifiers.includes('shift')) { options['shiftKey'] = true; }
            if (modifiers.includes('alt')) { options['altKey'] = true; }
            node.dispatchEvent(new MouseEvent('mousedown', options));
            node.dispatchEvent(new MouseEvent('mouseup', options));
            node.dispatchEvent(new MouseEvent('contextmenu', options));
            return options;
          }, AllElementHandles[#{node.handle}]);
          await Promise.race([response_watcher, navigation_watcher]);
        JAVASCRIPT
      end

      def node_save_screenshot(node, path, **options)
        # https://pptr.dev/#?product=Puppeteer&version=v1.12.2&show=api-pagescreenshotoptions
        absolute_path = File.absolute_path(path)
        final_options = ["path: '#{absolute_path}'"]
        if options.has_key?(:format)
          options[:format] = 'jpeg' if options[:format].to_s.downcase == 'jpg'
          final_options << "type: '#{options.delete(:format).to_s.downcase}'"
        end
        final_options << "quality: #{options.delete(:quality)}" if options.has_key?(:quality)
        box = await "LastResult = await AllElementHandles[#{node.handle}].boundingBox();"
        final_options << "clip: {x: #{box['x']}, y: #{box['y']}, width: #{box['width']}, height: #{box['height']}}"
        options.each { |k,v| final_options << "#{k.to_s.camelize(:lower)}: #{v}" }
        await "await AllPageHandles[#{node.document.handle}].screenshot({#{final_options.join(', ')}});"
      end

      def node_scroll_by(node, x, y)
        await <<~JAVASCRIPT
          await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node) {
            node.scrollBy(#{x}, #{y});
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_scroll_into_view(node)
        await <<~JAVASCRIPT
          await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node) {
            node.scrollIntoView();
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_scroll_to(node, x, y)
        await <<~JAVASCRIPT
          await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node) {
            node.scrollTo(#{x}, #{y});
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_select(node)
        # In the case of an OPTION tag, the change event should come
        # from the parent SELECT
        await <<~JAVASCRIPT
          await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node){
            var xpath = "parent::optgroup[@disabled] | ancestor::select[@disabled] | parent::fieldset[@disabled] | \
                         ancestor::*[not(self::legend) or preceding-sibling::legend][parent::fieldset[@disabled]]";
            if (node.disabled || document.evaluate(xpath, node, null, XPathResult.BOOLEAN_TYPE, null).booleanValue) { return false; } 
            else if (node.value == false && !node.parentNode.multiple) { return false; } 
            else {
              node.parentNode.dispatchEvent(new FocusEvent('focus',{bubbles: true, cancelable: true}));
              node.selected = true;
              var element;
              if (node.nodeName == "OPTION") {
                element = node.parentNode;
                if (element.nodeName == "OPTGROUP") { element = element.parentNode; }
              } else { element = node; }
              element.dispatchEvent(new Event('change',{bubbles: true, cancelable: false}));
              node.parentNode.dispatchEvent(new FocusEvent('blur',{bubbles: true, cancelable: true}));
              return true;
            }
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_style(node, *styles)
        await <<~JAVASCRIPT
          var handle = await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node, styles){
            var style = window.getComputedStyle(node);
            if (styles.length > 0) { 
              return styles.reduce(function(res,name) {
                res[name] = style[name];
                return res;
              }, {});
            } else { return style; }
          }, AllElementHandles[#{node.handle}], #{styles});
          LastResult = await handle.jsonValue();
        JAVASCRIPT
      end

      def node_type_keys(node, *keys)
        cjs = "await AllElementHandles[#{node.handle}].focus();\n"
        top_modifiers = []
        keys.each do |key|
          if key.is_a?(String)
            key.each_char do |c|
              need_shift = /[[:upper:]]/.match(c)
              cjs << "await AllPageHandles[#{node.document.handle}].keyboard.down('Shift');\n" if need_shift
              c = "Key#{c.upcase}" if /[[:alpha:]]/.match(c)
              cjs << "await AllPageHandles[#{node.document.handle}].keyboard.press('#{c}');\n"
              cjs << "await AllPageHandles[#{node.document.handle}].keyboard.up('Shift');\n" if need_shift
            end
          elsif key.is_a?(Symbol)
            if %i[ctrl Ctrl].include?(key)
              key = :control
            elsif  %i[command Command Meta].include?(key)
              key = :meta
            elsif  %i[divide Divide].include?(key)
              key = :numpad_divide
            elsif  %i[decimal Decimal].include?(key)
              key = :numpad_decimal
            elsif %i[left right up down].include?(key)
              key = "arrow_#{key}".to_sym
            end
            if %i[alt alt_left alt_right control control_left control_rigth meta meta_left meta_right shift shift_left shift_right].include?(key)
              top_modifiers << key
              cjs << "await AllPageHandles[#{node.document.handle}].keyboard.down('#{key.to_s.camelize}');\n"
            else
              cjs << "await AllElementHandles[#{node.handle}].press('#{key.to_s.camelize}');\n"
            end
          elsif key.is_a?(Array)
            modifiers = []
            key.each do |k|
              if k.is_a?(Symbol)
                if %i[ctrl Ctrl].include?(k)
                  k = :control
                elsif  %i[command Command Meta].include?(k)
                  k = :meta
                elsif  %i[divide Divide].include?(k)
                  k = :numpad_divide
                elsif  %i[decimal Decimal].include?(k)
                  k = :numpad_decimal
                elsif %i[left right up down].include?(key)
                  k = "arrow_#{key}".to_sym
                end
                if %i[alt alt_left alt_right control control_left control_rigth meta meta_left meta_right shift shift_left shift_right].include?(k)
                  modifiers << k
                  cjs << "await AllPageHandles[#{node.document.handle}].keyboard.down('#{k.to_s.camelize}');\n"
                else
                  cjs << "await AllElementHandles[#{node.handle}].press('#{k.to_s.camelize}');\n"
                end
              elsif k.is_a?(String)
                k.each_char do |c|
                  need_shift = /[[:upper:]]/.match(c)
                  cjs << "await AllPageHandles[#{node.document.handle}].keyboard.down('Shift');\n" if need_shift
                  c = "Key#{c.upcase}" if /[[:alpha:]]/.match(c)
                  cjs << "await AllPageHandles[#{node.document.handle}].keyboard.press('#{c}');\n"
                  cjs << "await AllPageHandles[#{node.document.handle}].keyboard.up('Shift');\n" if need_shift
                end
              end
            end
            modifiers.reverse.each do |k|
              cjs << "await AllPageHandles[#{node.document.handle}].keyboard.up('#{k.to_s.camelize}');\n"
            end
          end
        end
        top_modifiers.reverse.each do |key|
          cjs << "await AllPageHandles[#{node.document.handle}].keyboard.up('#{key.to_s.camelize}');\n"
        end
        await(cjs)
      end

      def node_unselect(node)
        # In the case of an OPTION tag, the change event should come
        # from the parent SELECT
        await <<~JAVASCRIPT
          await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node){
            var xpath = "parent::optgroup[@disabled] | ancestor::select[@disabled] | parent::fieldset[@disabled] | \
                         ancestor::*[not(self::legend) or preceding-sibling::legend][parent::fieldset[@disabled]]";
            if (node.disabled || document.evaluate(xpath, node, null, XPathResult.BOOLEAN_TYPE, null).booleanValue) { return false; }
            else if (node.value == false && !node.parentNode.multiple) { return false; }
            else {
              node.parentNode.dispatchEvent(new FocusEvent('focus',{bubbles: true, cancelable: true}));
              node.selected = false;
              var element;
              if (node.nodeName == "OPTION") {
                element = node.parentNode;
                if (element.nodeName == "OPTGROUP") { element = element.parentNode; }
              } else { element = node; }
              element.dispatchEvent(new Event('change',{bubbles: true, cancelable: false}));
              node.parentNode.dispatchEvent(new FocusEvent('blur',{bubbles: true, cancelable: true}));
              return true;
            }
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_value(node)
        await <<~JAVASCRIPT
          LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node){
            if (node.tagName == "SELECT" && node.multiple) {
              var result = []
              for (let i = 0, len = node.children.length; i < len; i++) {
                var option = node.children[i];
                if (option.selected) { result.push(option.value); }
              }
              return result;
            } else if (node.isContentEditable) { return node.textContent; }
            else { return node.value; }
          }, AllElementHandles[#{node.handle}]);
        JAVASCRIPT
      end

      def node_value=(node, value)
        raise Isomorfeus::Puppetmaster::ReadOnlyElementError if node.readonly?
        real_value = "`#{value}`"
        if %w[input textarea].include?(node.tag)
          await <<~JAVASCRIPT
            await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node, value){
              if (node.maxLength >= 0) { value = value.substr(0, node.maxLength); }
              node.dispatchEvent(new FocusEvent("focus",{bubbles: true, cancelable: true}));
              var tag_name = node.tagName.toLowerCase();
              if (tag_name === 'input') {
                node.value = '';
                if (node.type === "number" || node.type === "date") { 
                  for (var i = 0; i < value.length; i++) {
                    node.dispatchEvent(new KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                    node.dispatchEvent(new KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                    node.dispatchEvent(new KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                  }
                  node.value = value;
                }
                else if (node.type == "time") { node.value = new Date(value).toTimeString().split(" ")[0]; }
                else if (node.type == "datetime-local") {
                  value = new Date(value);
                  var year = value.getFullYear();
                  var month = ("0" + (value.getMonth() + 1)).slice(-2);
                  var date = ("0" + value.getDate()).slice(-2);
                  var hour = ("0" + value.getHours()).slice(-2);
                  var min = ("0" + value.getMinutes()).slice(-2);
                  var sec = ("0" + value.getSeconds()).slice(-2);
                  value = `${year}-${month}-${date}T${hour}:${min}:${sec}`;
                  for (var i = 0; i < value.length; i++) {
                    node.dispatchEvent(new KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                    node.value = node.value + value[i];
                    node.dispatchEvent(new KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                    node.dispatchEvent(new KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                  }
                } else if (node.type === 'checkbox' || node.type === 'radio') { node.checked = value; }
                else {
                  for (var i = 0; i < value.length; i++) {
                    node.dispatchEvent(new KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                    node.value = node.value + value[i];
                    node.dispatchEvent(new KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                    node.dispatchEvent(new KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                  }
                }
              } else if (tag_name === 'textarea') {
                for (var i = 0; i < value.length; i++) {
                  node.dispatchEvent(new KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                  node.value = node.value + value[i];
                  node.dispatchEvent(new KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                  node.dispatchEvent(new KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                }
              }
            }, AllElementHandles[#{node.handle}], #{real_value});
          JAVASCRIPT
        else
          await <<~JAVASCRIPT
            await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node, value){
              if (node.isContentEditable) {
                var range = document.createRange();
                range.selectNodeContents(node);
                window.getSelection().removeAllRanges();
                window.getSelection().addRange(range);
                window.getSelection().deleteFromDocument();
                window.getSelection().removeAllRanges();
                node.dispatchEvent(new KeyboardEvent("keydown", {key: value[0], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                node.textContent = value;
                node.dispatchEvent(new KeyboardEvent("keyup", {key: value[0], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
              }
            }, AllElementHandles[#{node.handle}], #{real_value});
          JAVASCRIPT
        end
        real_value
      end

      def node_visible_text(node)
        # if node is AREA, check visibility of relevant image
        text = await <<~JAVASCRIPT
          var handle = await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node){
            var temp_node = node;
            var mapName, style;
            if (node.tagName === "AREA") {
              mapName = document.evaluate("./ancestor::map/@name", node, null, XPathResult.STRING_TYPE, null).stringValue;
              temp_node = document.querySelector(`img[usemap="#${mapName}"]`);
              if (temp_node == null) { return ''; }
            }
            temp_node = node;
            while (temp_node) {
              style = window.getComputedStyle(node);
              if (style.display === "none" || style.visibility === "hidden" || parseFloat(style.opacity) === 0) { return ''; }
              temp_node = temp_node.parentElement;
            }
            if (node.nodeName == "TEXTAREA" || node instanceof SVGElement) { return node.textContent; }
            else { return node.innerText; }
          }, AllElementHandles[#{node.handle}]);
          LastResult = await handle.jsonValue();
        JAVASCRIPT
        text.gsub(/\A[[:space:]&&[^\u00a0]]+/, "").gsub(/[[:space:]&&[^\u00a0]]+\z/, "").gsub(/\n+/, "\n").tr("\u00a0", " ")
      end

      def node_visible?(node)
        await <<~JAVASCRIPT
          var handle = await AllElementHandles[#{node.handle}].executionContext().evaluateHandle(function(node){
            if (node.tagName == 'AREA'){
              const map_name = document.evaluate('./ancestor::map/@name', node, null, XPathResult.STRING_TYPE, null).stringValue;
              node = document.querySelector(`img[usemap='#${map_name}']`);
              if (!node){ return false; }
            }
            var forced_visible = false;
            while (node) {
              const style = window.getComputedStyle(node);
              if (style.visibility == 'visible') { forced_visible = true; }
              if ((style.display == 'none') || ((style.visibility == 'hidden') && !forced_visible) || (parseFloat(style.opacity) == 0)) {
                return false;
              }
              node = node.parentElement;
            }
            return true;
          }, AllElementHandles[#{node.handle}]);
          LastResult = await handle.jsonValue();
        JAVASCRIPT
      end

      def node_wait_for(node, selector)
        # TODO setTimeout
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle = await AllElementHandles[#{node.handle}].$("#{js_escaped_selector}");
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var handle = await AllElementHandles[node_handle].evaluate((node) => {
              var tag = node.tagName.toLower();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type];
            }, AllElementHandles[node_handle]);
            var tt = await handle.jsonValue();
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1]};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def node_wait_for_xpath(node, query)
        # TODO setTimeout
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var element_handle_array = await AllElementHandles[#{node.handle}].$x("#{js_escaped_query}");
          var element_handle = (element_handle_array) ? element_handle_array[0] : null;
          if (element_handle) {
            var node_handle = RegisterElementHandle(element_handle);
            var handle = await AllElementHandles[node_handle].evaluate((node) => {
              var tag = node.tagName.toLower();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [tag, type];
            }, AllElementHandles[node_handle]);
            var tt = await handle.jsonValue();
            LastResult = {handle: node_handle, tag: tt[0], type: tt[1]};
          }
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      private

      def self.close_browser(driver)
        cjs = <<~JAVASCRIPT
          CurrentBrowser.close()
        JAVASCRIPT
        proc { driver.await(cjs) }
      end

      def await(script)
        @context.eval <<~JAVASCRIPT
          (async () => {
            try {
              LastExecutionFinished = false;
              LastResult = null;
              LastErr = null;
              #{script}
              LastExecutionFinished = true;
            } catch(err) {
              LastResult = null;
              LastErr = err;
              LastExecutionFinished = true;
            }
          })()
        JAVASCRIPT
        await_result
      end

      def await_result
        start_time = Time.now
        while !execution_finished? && !timed_out?(start_time)
          sleep 0.01
        end
        get_result
      end

      def chromium_require
        <<~JAVASCRIPT
          const MasterPuppeteer = require('puppeteer');
        JAVASCRIPT
      end

      def determine_error(message)
        if message.include?('net::ERR_CERT_') || message.include?('SEC_ERROR_EXPIRED_CERTIFICATE')
          Isomorfeus::Puppetmaster::CertificateError.new(message)
        elsif message.include?('net::ERR_NAME_') || message.include?('NS_ERROR_UNKNOWN_HOST')
          Isomorfeus::Puppetmaster::DNSError.new(message)
        elsif message.include?('Unknown key: ')
          Isomorfeus::Puppetmaster::KeyError.new(message)
        elsif message.include?('Execution context was destroyed, most likely because of a navigation.')
          Isomorfeus::Puppetmaster::ExecutionContextError.new(message)
        elsif message.include?('Evaluation failed: DOMException:') || (message.include?('Evaluation failed:') && (message.include?('is not a valid selector') || message.include?('is not a legal expression')))
          Isomorfeus::Puppetmaster::DOMException.new(message)
        else
          Isomorfeus::Puppetmaster::JavaScriptError.new(message)
        end
      end

      def execution_finished?
        @context.eval 'LastExecutionFinished'
      end

      def firefox_require
        <<~JAVASCRIPT
          const MasterPuppeteer = require('puppeteer-firefox');
        JAVASCRIPT
      end

      def get_result
        res, err_msg = @context.eval 'GetLastResult()'
        raise determine_error(err_msg) if err_msg
        res
      end

      def launch_line
        string_options = []
        options = @options.dup
        string_options << "ignoreHTTPSErrors: #{options.delete(:ignore_https_errors)}" if options.has_key?(:ignore_https_errors)
        string_options << "executablePath: '#{options.delete(:executable_path)}'" if options.has_key?(:executable_path)
        options.each do |option, value|
          string_options << "#{option.to_s.camelize(:lower)}: #{value}"
        end
        string_options << "userDataDir: '#{Dir.mktmpdir}'" unless @options.has_key?(:user_data_dir)
        string_options << "defaultViewport: { width: #{@width}, height: #{@height} }"
        string_options << "pipe: true"
        # string_options << "args: ['--disable-popup-blocking']"
        line = 'await MasterPuppeteer.launch('
        unless string_options.empty?
          line << '{'
          line << string_options.join(', ') if string_options.size > 1
          line << '}'
        end
        line << ')'
      end

      def puppeteer_launch
        # todo target_handle, puppeteer save path
        puppeteer_require = case @browser_type
                            when :firefox then firefox_require
                            when :chrome then chromium_require
                            when :chromium then chromium_require
                            else
                              raise "Browser type #{@browser_type} not supported! Browser type must be one of: chrome, firefox."
                            end
        <<~JAVASCRIPT
          #{puppeteer_require}
          var BrowserType = '#{@browser_type.to_s}';
          var LastResult = null;
          var LastErr = null;
          var LastExecutionFinished = false;
          var LastHandleId = 0;
  
          var AllPageHandles = {};
          var AllElementHandles = {};
  
          var CurrentBrowser = null;
          var ConsoleMessages = {};
  
          var ModalText = null;
          var ModalTextMatched = false;
  
          const GetLastResult = function() {
            if (LastExecutionFinished === true) {
              var err = LastErr;
              var res = LastResult;
  
              LastErr = null;
              LastRes = null;
              LastExecutionFinished = false;
  
              if (err) { return [null, err.message]; }
              else { return [res, null]; }
  
            } else {
              return [null, (new Error('Last command did not yet finish execution!')).message];
            }
          };
  
          const DialogAcceptHandler = async (dialog) => {
            var msg = dialog.message()
            ModalTextMatched = (ModalText === msg);
            ModalText = msg;
            await dialog.accept();
          }
  
          const DialogDismissHandler = async (dialog) => {
            var msg = dialog.message()
            ModalTextMatched = (ModalText === msg);
            ModalText = msg;
            await dialog.dismiss();
          }
  
          const RegisterElementHandle = function(element_handle) {
            var entries = Object.entries(AllElementHandles);
            for(var i = 0; i < entries.length; i++) { 
              if (entries[i][1] === element_handle) { return entries[i][0]; }
            }
            LastHandleId++;
            var handle_id = LastHandleId;
            AllElementHandles[handle_id] = element_handle;
            return handle_id; 
          };
  
          const RegisterPage = function(page) {
            var entries = Object.entries(AllPageHandles);
            for(var i = 0; i < entries.length; i++) { 
              if (entries[i][1] === page) { return entries[i][0]; }
            }
            LastHandleId++;
            var handle_id = LastHandleId;
            AllPageHandles[handle_id] = page;
            ConsoleMessages[handle_id] = [];
            AllPageHandles[handle_id].on('console', (msg) => {
              ConsoleMessages[handle_id].push({level: msg.type(), location: msg.location(), text: msg.text()});
            });
            AllPageHandles[handle_id].on('pageerror', (error) => {
              ConsoleMessages[handle_id].push({level: 'error', location: '', text: error.message});
            });
            return handle_id; 
          };
  
          (async () => {
            try {
              CurrentBrowser = #{launch_line}
              var page = (await CurrentBrowser.pages())[0];
              page.setDefaultTimeout(#{@puppeteer_timeout});
              if (!(BrowserType === 'firefox')) {
                var target = page.target();
                var cdp_session = await target.createCDPSession();
                await cdp_session.send('Page.setDownloadBehavior', {behavior: 'allow', downloadPath: '#{Isomorfeus::Puppetmaster.save_path}'});
                if (#{@url_blacklist}.length > 0) { await cdp_session.send('Network.setBlockedURLs', {urls: #{@url_blacklist}}); }
                await cdp_session.detach();
              }
              LastResult = RegisterPage(page);
              LastExecutionFinished = true;
            } catch (err) {
              LastErr = err;
              LastExecutionFinished = true;
            }
          })();
        JAVASCRIPT
      end

      def session
        @session
      end

      def timed_out?(start_time)
        if (Time.now - start_time) > @timeout
          raise "Command Execution timed out!"
        end
        false
      end
    end
  end
end
