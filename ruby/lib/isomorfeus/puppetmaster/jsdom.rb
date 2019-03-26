module Isomorfeus
  module Puppetmaster
    class Jsdom
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

      attr_accessor :default_document

      def initialize(options = {})
        @app = options.delete(:app)
        @options = options.dup
        @ignore_https_errors = !!@options.delete(:ignore_https_errors)
        @max_width = @options.delete(:max_width) { VIEWPORT_MAX_WIDTH }
        @max_height = @options.delete(:max_height) { VIEWPORT_MAX_HEIGHT }
        @width = @options.delete(:width) { VIEWPORT_DEFAULT_WIDTH > @max_width ? @max_width : VIEWPORT_DEFAULT_WIDTH }
        @height = @options.delete(:height) { VIEWPORT_DEFAULT_HEIGHT > @max_height ? @max_height : VIEWPORT_DEFAULT_HEIGHT }
        @timeout = @options.delete(:timeout) { TIMEOUT }
        @max_wait = @options.delete(:max_wait) { @timeout + 1 }
        @reaction_timeout = @options.delete(:reaction_timeout) { REACTION_TIMEOUT }
        @jsdom_timeout = @timeout * 1000
        @jsdom_reaction_timeout = @reaction_timeout * 1000
        @url_blacklist = @options.delete(:url_blacklist) { [] }
        @context = ExecJS.permissive_compile(jsdom_launch)
        page_handle, @browser = await_result
        @default_document = Isomorfeus::Puppetmaster::Document.new(self, page_handle, Isomorfeus::Puppetmaster::Response.new('status' => 200))
      end

      def self.document_handle_disposer(driver, handle)
        cjs = <<~JAVASCRIPT
          delete AllDomHandles[#{handle}];
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
        @browser
      end

      def document_handles
        @context.eval 'Object.keys(AllDomHandles)'
      end

      def document_accept_alert(document, **options, &block)
        raise Isomorfeus::Puppetmaster::NotSupported
        # TODO maybe wrap in mutex
      #   text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
      #   @context.exec <<~JAVASCRIPT
      #     ModalText = #{text};
      #     AllDomHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   block.call
      #   sleep @reaction_timeout
      #   @context.eval 'ModalText'
      # ensure
      #   matched = await <<~JAVASCRIPT
      #     LastResult = ModalTextMatched;
      #     ModalTextMatched = false;
      #     ModalText = null;
      #     AllDomHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_accept_confirm(document, **options, &block)
        raise Isomorfeus::Puppetmaster::NotSupported
        # TODO maybe wrap in mutex
      #   text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
      #   @context.exec <<~JAVASCRIPT
      #     ModalText = #{text};
      #     AllDomHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   block.call
      #   sleep @reaction_timeout
      #   @context.eval 'ModalText'
      # ensure
      #   matched = await <<~JAVASCRIPT
      #     LastResult = ModalTextMatched;
      #     ModalTextMatched = false;
      #     ModalText = null;
      #     AllDomHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_accept_leave_page(document, **options, &block)
        raise Isomorfeus::Puppetmaster::NotSupported
        # TODO maybe wrap in mutex
      #   text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
      #   @context.exec <<~JAVASCRIPT
      #     ModalText = #{text};
      #     AllDomHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   block.call
      #   sleep @reaction_timeout
      #   @context.eval 'ModalText'
      # ensure
      #   matched = await <<~JAVASCRIPT
      #     LastResult = ModalTextMatched;
      #     ModalTextMatched = false;
      #     ModalText = null;
      #     AllDomHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_accept_prompt(document, **options, &block)
        raise Isomorfeus::Puppetmaster::NotSupported
      #   # TODO maybe wrap in mutex
      #   text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
      #   @context.exec <<~JAVASCRIPT
      #     ModalText = #{text};
      #     AllDomHandles[#{document.handle}].on('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   block.call
      #   sleep @reaction_timeout
      #   @context.eval 'ModalText'
      # ensure
      #   matched = await <<~JAVASCRIPT
      #     LastResult = ModalTextMatched;
      #     ModalTextMatched = false;
      #     ModalText = null;
      #     AllDomHandles[#{document.handle}].removeListener('dialog', DialogAcceptHandler);
      #   JAVASCRIPT
      #   raise Isomorfeus::Puppetmaster::NoModalError if options.has_key?(:text) && !matched
      end

      def document_all_text(document)
        @context.eval "AllDomHandles[#{document.handle}].window.document.documentElement.textContent"
      end

      def document_body(document)
        node_data = @context.exec <<~JAVASCRIPT
          var node = AllDomHandles[#{document.handle}].window.document.body;
          var node_handle = RegisterElementHandle(node);
          var tag = node.tagName.toLowerCase();
          return {handle: node_handle, tag: tag, type: null, content_editable: node.isContentEditable};
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = 'body'
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_bring_to_front(_document); end

      def document_clear_authentication_credentials(document)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_clear_cookies(document)
        @context.exec "AllDomHandles[#{document.handle}].cookieJar.removeAllCookiesSync()"
      end

      def document_clear_extra_headers(document)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_clear_url_blacklist(document)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_click(document, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # raise Isomorfeus::Pupppetmaster::InvalidActionError.new(:click) unless visible?
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        @context.exec <<~JAVASCRIPT
          var options = {button: 0, bubbles: true, cancelable: true};
          var window = AllDomHandles[#{document.handle}].window;
          var modifiers = #{modifiers};
          if (modifiers.includes('meta')) { options['metaKey'] = true; }
          if (modifiers.includes('control')) { options['ctrlKey'] = true; }
          if (modifiers.includes('shift')) { options['shiftKey'] = true; }
          if (modifiers.includes('alt')) { options['altKey'] = true; }
          var x = #{x ? x : 'null'};
          var y = #{y ? y : 'null'};
          if (x && y) {
            options['clientX'] = x;
            options['clientY'] = y;
          }  
          window.document.dispatchEvent(new window.MouseEvent('mousedown', options));
          window.document.dispatchEvent(new window.MouseEvent('mouseup', options));
          window.document.dispatchEvent(new window.MouseEvent('click', options));
        JAVASCRIPT
      end

      def document_close(document)
        await <<~JAVASCRIPT
          delete AllDomHandles[#{document.handle}];
          delete AllConsoleHandles[#{document.handle}];
          delete ConsoleMessages[#{document.handle}];
        JAVASCRIPT
      end

      def document_console(document)
        messages = @context.eval "ConsoleMessages[#{document.handle}]"
        messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
      end

      def document_cookies(document)
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
        result = @context.eval "AllDomHandles[#{document.handle}].cookieJar.getCookiesSync('#{uri.to_s}')"
        result.to_h do |cookie|
          cookie['name'] = cookie['key']
          cookie['expires'] = DateTime.parse(cookie['expires']).to_time if cookie.has_key?('expires')
          [cookie['name'], Isomorfeus::Puppetmaster::Cookie.new(cookie)]
        end
      end

      def document_dismiss_confirm(document, **options, &block)
        # TODO
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllDomHandles[#{document.handle}].on('dialog', DialogDismissHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllDomHandles[#{document.handle}].removeListener('dialog', DialogDismissHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::ModalNotFound if options.has_key?(:text) && !matched
      end

      def document_dismiss_leave_page(document, **options, &block)
        # TODO
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllDomHandles[#{document.handle}].on('dialog', DialogDismissHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllDomHandles[#{document.handle}].removeListener('dialog', DialogDismissHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::ModalNotFound if options.has_key?(:text) && !matched
      end

      def document_dismiss_prompt(document, **options, &block)
        # TODO
        text =  options.has_key?(:text) ? "`#{options[:text]}`" : 'null'
        @context.exec <<~JAVASCRIPT
          ModalText = #{text};
          AllDomHandles[#{document.handle}].on('dialog', DialogDismissHandler);
        JAVASCRIPT
        block.call
        sleep @reaction_timeout
        @context.eval 'ModalText'
      ensure
        matched = await <<~JAVASCRIPT
          LastResult = ModalTextMatched;
          ModalTextMatched = false;
          ModalText = null;
          AllDomHandles[#{document.handle}].removeListener('dialog', DialogDismissHandler);
        JAVASCRIPT
        raise Isomorfeus::Puppetmaster::ModalNotFound if options.has_key?(:text) && !matched
      end

      def document_dispatch_event(document, name, event_type = nil, **options)
        raise ArgumentError, 'Unknown event' unless EVENTS.key?(name.to_sym) || event_type
        event_type, opts = *EVENTS[name.to_s.downcase.tr('_', '').to_sym] if event_type.nil?
        opts.merge!(options)
        final_options = options.map { |k,v| "#{k}: '#{v}'" }
        @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{document.handle}].window;
          var event = new window.#{event_type}('#{name}', { #{final_options.join(', ')} });
          window.document.dispatchEvent(event);
        JAVASCRIPT
      end

      def document_double_click(document, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var options = {button: 0, bubbles: true, cancelable: true};
          var window = AllDomHandles[#{document.handle}].window;
          var modifiers = #{modifiers};
          if (modifiers.includes('meta')) { options['metaKey'] = true; }
          if (modifiers.includes('control')) { options['ctrlKey'] = true; }
          if (modifiers.includes('shift')) { options['shiftKey'] = true; }
          if (modifiers.includes('alt')) { options['altKey'] = true; }
          var x = #{x ? x : 'null'};
          var y = #{y ? y : 'null'};
          if (x && y) {
            options['clientX'] = x;
            options['clientY'] = y;
          } 
          window.document.dispatchEvent(new window.MouseEvent('mousedown', options));
          window.document.dispatchEvent(new window.MouseEvent('mouseup', options));
          window.document.dispatchEvent(new window.MouseEvent('dblclick', options));
        JAVASCRIPT
      end

      def document_evaluate_script(document, script, *args)
        @context.eval <<~JAVASCRIPT
          AllDomHandles[#{document.handle}].window.eval(
            `var arguments = #{args};
            #{script}` 
          )
        JAVASCRIPT
      rescue ExecJS::ProgramError => e
        raise determine_error(e.message)
      end

      def document_execute_script(document, script, *args)
        @context.eval <<~JAVASCRIPT
          AllDomHandles[#{document.handle}].window.eval(
            `(function() { var arguments = #{args};
             #{script}
            })()` 
          )
        JAVASCRIPT
      rescue ExecJS::ProgramError => e
        raise determine_error(e.message)
      end

      def document_find(document, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = @context.exec <<~JAVASCRIPT
          var node = AllDomHandles[#{document.handle}].window.document.querySelector("#{js_escaped_selector}");
          if (node) {
            var node_handle = RegisterElementHandle(node);
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            return {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(selector)
        end
      rescue Exception => e
        raise determine_error(e.message)
      end

      def document_find_all(document, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = @context.exec <<~JAVASCRIPT
          var node_array = AllDomHandles[#{document.handle}].window.document.querySelectorAll("#{js_escaped_selector}");
          var node_data_array = [];
          if (node_array) {
            for (var i=0; i<node_array.length; i++) {
              var node_handle = RegisterElementHandle(node_array[i]);
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              node_data_array.push({handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable});
            }
          }
          return node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_find_all_xpath(document, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{document.handle}].window;
          var document = window.document;
          var xpath_result = document.evaluate("#{js_escaped_query}", document, null, window.XPathResult.ORDERED_NODE_ITERATOR_TYPE, null);
          var node;
          var node_data_array = [];
          while (node = xpath_result.iterateNext) {
            var node_handle = RegisterElementHandle(node);
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            node_data_array.push({handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable});
          }  
          return node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_find_xpath(document, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{document.handle}].window;
          var document = window.document;
          var xpath_result = document.evaluate("#{js_escaped_query}", document, null, window.XPathResult.FIRST_ORDERED_NODE_TYPE, null);
          var node = xpath_result.singleNodeValue;
          if (node) {
            var node_handle = RegisterElementHandle(node);
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            return {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
          }
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(query)
        end
      rescue ExecJS::ProgramError => e
        raise determine_error('invalid xpath query')
      end

      def document_go_back(document)
        raise 'Browser history not supported.'
        @context.eval "AllDomHandles[#{document.handle}].window.history.back()"
      end

      def document_go_forward(document)
        raise 'Browser history not supported.'
        @context.eval "AllDomHandles[#{document.handle}].window.history.forward()"
      end

      def document_goto(document, uri)
        parsed_uri = URI.parse(uri)
        parsed_uri.host = @app.host unless parsed_uri.host
        parsed_uri.port = @app.port unless parsed_uri.port
        parsed_uri.scheme = @app.scheme unless parsed_uri.scheme
        response_hash, messages = await <<~JAVASCRIPT
          ConsoleMessages[#{document.handle}] = [];
          var cookie_jar = AllDomHandles[#{document.handle}].cookieJar.cloneSync(new MemoryCookieStore());
          cookie_jar.rejectPublicSuffixes = false;
          var con = new jsdom.VirtualConsole()
          con.on('error', (msg) => { ConsoleMessages[#{document.handle}].push({level: 'error', location: '', text: msg}); });
          con.on('warn', (msg) => { ConsoleMessages[#{document.handle}].push({level: 'warn', location: '', text: msg}); });
          con.on('info', (msg) => { ConsoleMessages[#{document.handle}].push({level: 'info', location: '', text: msg}); });
          con.on('log', (msg) => { ConsoleMessages[#{document.handle}].push({level: 'dir', location: '', text: msg}); });
          con.on('debug', (msg) => { ConsoleMessages[#{document.handle}].push({level: 'dir', location: '', text: msg}); });
          AllConsoleHandles[#{document.handle}] = con;
          try {
            var new_dom = await JSDOM.fromURL('#{parsed_uri.to_s}', Object.assign({}, JSDOMOptions, { cookieJar: cookie_jar, virtualConsole: con }));
            AllDomHandles[#{document.handle}] = new_dom;
            var formatted_response = {
              headers: {},
              ok: true,
              remote_address: '#{parsed_uri.to_s}',
              request: {},
              status: 200,
              status_text: '',
              text: '',
              url: '#{parsed_uri.to_s}'
            };
            LastResult = [formatted_response, ConsoleMessages[#{document.handle}]];
          } catch (err) {
            var formatted_error_response = {
              headers: err.options.headers,
              ok: false,
              remote_address: '#{parsed_uri.to_s}',
              request: {},
              status: err.statusCode ? err.statusCode : 500,
              status_text: err.response ? err.response.statusMessage : '',
              text: err.message ? err.message : '',
              url: '#{parsed_uri.to_s}'
            };
            LastResult = [formatted_error_response, ConsoleMessages[#{document.handle}]];
          }
        JAVASCRIPT
        con_messages = messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
        # STDERR.puts 'M', con_messages
        # STDERR.puts 'R', response_hash
        con_messages.each { |m| raise determine_error(m.text) if m.level == 'error' && !m.text.start_with?('Failed to load resource:') }
        if response_hash
          response = Isomorfeus::Puppetmaster::Response.new(response_hash)
          if response.status == 500 && response.text.start_with?('Error:')
            error = determine_error(response.text)
            raise error if error
          end
          document.instance_variable_set(:@response, response)
        end
        document.response
      end

      def document_head(document)
        node_data = @context.exec <<~JAVASCRIPT
          var node = AllDomHandles[#{document.handle}].window.document.head;
          var node_handle = RegisterElementHandle(node);
          var tag = node.tagName.toLowerCase();
          return {handle: node_handle, tag: tag, type: null, content_editable: node.isContentEditable};
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = 'body'
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_html(document)
        @context.eval "AllDomHandles[#{document.handle}].serialize()"
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
          var con = new jsdom.VirtualConsole();
          var jar = new jsdom.CookieJar(new MemoryCookieStore(), {rejectPublicSuffixes: false, looseMode: true});
          var handle_id = RegisterCon(con);
          con.on('error', (msg) => { ConsoleMessages[handle_id].push({level: 'error', location: '', text: msg}); });
          con.on('warn', (msg) => { ConsoleMessages[handle_id].push({level: 'warn', location: '', text: msg}); });
          con.on('info', (msg) => { ConsoleMessages[handle_id].push({level: 'info', location: '', text: msg}); });
          con.on('log', (msg) => { ConsoleMessages[handle_id].push({level: 'dir', location: '', text: msg}); });
          con.on('debug', (msg) => { ConsoleMessages[handle_id].push({level: 'dir', location: '', text: msg}); });
          try {
            var new_dom;
            var uri = '#{parsed_uri.to_s}';
            if (uri === 'about:blank') {
              new_dom = new JSDOM('', Object.assign({}, JSDOMOptions, { cookieJar: jar, virtualConsole: con }));
            } else {
              new_dom = await JSDOM.fromURL(uri, Object.assign({}, JSDOMOptions, { cookieJar: jar, virtualConsole: con }));
            }
            AllDomHandles[handle_id] = new_dom;
            var formatted_response = {
              headers: {},
              ok: false,
              remote_address: '#{parsed_uri.to_s}',
              request: {},
              status: 200,
              status_text: '',
              text: '',
              url: '#{parsed_uri.to_s}'
            };
            LastResult = [handle_id, formatted_response, ConsoleMessages[handle_id]];
          } catch (err) {
            var formatted_response = {
              headers: err.options.headers,
              ok: true,
              remote_address: '#{parsed_uri.to_s}',
              request: {},
              status: err.statusCode,
              status_text: err.response ? err.response.statusMessage : '',
              text: '',
              url: '#{parsed_uri.to_s}'
            };
            LastResult = [handle_id, formatted_response, ConsoleMessages[handle_id]];
          }
        JAVASCRIPT
        # STDERR.puts 'R', response_hash
        # STDERR.puts 'C', messages
        con_messages = messages.map {|m| Isomorfeus::Puppetmaster::ConsoleMessage.new(m)}
        con_messages.each { |m| raise determine_error(m.text) if m.level == 'error' && !m.text.start_with?('Failed to load resource:') }
        response = Isomorfeus::Puppetmaster::Response.new(response_hash)
        if response.status == 500 && response.text.start_with?('Error:')
          error = determine_error(response.text)
          raise error if error
        end
        Isomorfeus::Puppetmaster::Document.new(self, handle, response)
      end

      def document_reload(document)
        document_goto(document, document_url(document))
      end

      def document_remove_cookie(document, name)
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
        domain = URI.parse(uri).host
        await <<~JAVASCRIPT
          var cookies = AllDomHandles[#{document.handle}].cookieJar.getCookiesSync('#{uri.to_s}')
          var path = '/';
          for(i=0; i<cookies.length; i++) {
            if (cookies[i].key === '#{name}' && cookies[i].domain === '#{domain}') {
              var path = cookies[i].path;
              break;
            }
          }
          var promise = new Promise(function(resolve, reject) {
            AllDomHandles[#{document.handle}].cookieJar.store.removeCookie('#{domain}', path, '#{name}', function(err){ resolve(true); });
          })
          await promise;
        JAVASCRIPT
      end

      def document_render_base64(document, **options)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_reset_user_agent(document)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_right_click(document, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var options = {button: 2, bubbles: true, cancelable: true};
          var window = AllDomHandles[#{document.handle}].window;
          var modifiers = #{modifiers};
          if (modifiers.includes('meta')) { options['metaKey'] = true; }
          if (modifiers.includes('control')) { options['ctrlKey'] = true; }
          if (modifiers.includes('shift')) { options['shiftKey'] = true; }
          if (modifiers.includes('alt')) { options['altKey'] = true; }
          var x = #{x ? x : 'null'};
          var y = #{y ? y : 'null'};
          if (x && y) {
            options['clientX'] = x;
            options['clientY'] = y;
          } 
          window.document.dispatchEvent(new window.MouseEvent('mousedown', options));
          window.document.dispatchEvent(new window.MouseEvent('mouseup', options));
          window.document.dispatchEvent(new window.MouseEvent('contextmenu', options));
        JAVASCRIPT
      end

      def document_save_pdf(document, **options)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_save_screenshot(document, file, **options)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_scroll_by(document, x, y)
        @context.exec <<~JAVASCRIPT
          AllDomHandles[#{document.handle}].window.scrollX = AllDomHandles[#{document.handle}].window.scrollX + #{x};
          AllDomHandles[#{document.handle}].window.scrollY = AllDomHandles[#{document.handle}].window.scrollY + #{y};
        JAVASCRIPT
      end

      def document_scroll_to(document, x, y)
        @context.exec <<~JAVASCRIPT
          AllDomHandles[#{document.handle}].window.scrollX = #{x};
          AllDomHandles[#{document.handle}].window.scrollY = #{y};
        JAVASCRIPT
      end

      def document_set_authentication_credentials(document, username, password)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_set_cookie(document, name, value, **options)
        options[:key]   ||= name
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
        final_options << "expires: new Date('#{options.delete(:expires).to_s}')" if options.has_key?(:expires)
        final_options << "httpOnly: #{options.delete(:http_only)}" if options.has_key?(:http_only)
        final_options << "secure: #{options.delete(:secure)}" if options.has_key?(:secure)
        final_options << "sameSite: '#{options.delete(:same_site)}'" if options.has_key?(:same_site)
        options.each do |k,v|
          final_options << "#{k}: '#{v}'"
        end
        @context.exec "AllDomHandles[#{document.handle}].cookieJar.setCookieSync(new Cookie({#{final_options.join(', ')}}), '#{uri.to_s}', {ignoreError: true})"
      end

      def document_set_extra_headers(document, headers_hash)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_set_user_agent(document, agent_string)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def document_title(document)
        @context.eval "AllDomHandles[#{document.handle}].window.document.title"
      end

      def document_type_keys(document, *keys)
        cjs = <<~JAVASCRIPT
         var window = AllDomHandles[#{document.handle}].window;
         var events = [];
         var options = {bubbles: true, cancelable: true};
        JAVASCRIPT
        top_modifiers = []
        keys.each do |key|
          if key.is_a?(String)
            key.each_char do |c|
              shift = !! /[[:upper:]]/.match(c)
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{shift || need_shift?(top_modifiers)}}));
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{shift || need_shift?(top_modifiers)}}));
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{shift || need_shift?(top_modifiers)}}));
              JAVASCRIPT
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
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
            else
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
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
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                else
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                end
              elsif k.is_a?(String)
                k.each_char do |c|
                  shift = !! /[[:upper:]]/.match(c)
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{shift || need_shift?(modifiers)}}));
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{shift || need_shift?(modifiers)}}));
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{shift || need_shift?(modifiers)}}));
                  JAVASCRIPT
                end
              end
            end
            modifiers.reverse.each do |k|
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                  altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                  shiftKey: #{need_shift?(modifiers)}}));
              JAVASCRIPT
            end
          end
        end
        top_modifiers.reverse.each do |key|
          cjs << <<~JAVASCRIPT
            events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
              altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
              shiftKey: #{need_shift?(top_modifiers)}}));
          JAVASCRIPT
        end
        cjs << <<~JAVASCRIPT
          for (i=0; i<events.length; i++) {
            window.document.dispatchEvent(events[i]);
          }
        JAVASCRIPT
        @context.exec cjs
      end

      def document_url(document)
        @context.eval "AllDomHandles[#{document.handle}].window.location.href"
      end

      def document_user_agent(document)
        @context.eval "AllDomHandles[#{document.handle}].window.navigator.userAgent"
      end

      def document_viewport_maximize(document)
        document_viewport_resize(document, @max_width, @max_height)
      end

      def document_viewport_resize(document, width, height)
        width = @max_width if width > @max_width
        height = @max_height if width > @max_height
        @context.exec <<~JAVASCRIPT
          AllDomHandles[#{document.handle}].window.innerWidth = #{width};
          AllDomHandles[#{document.handle}].window.innerHeight = #{height};
        JAVASCRIPT
      end

      def document_viewport_size(document)
        @context.eval "[AllDomHandles[#{document.handle}].window.innerWidth, AllDomHandles[#{document.handle}].window.innerHeight]"
      end

      def document_wait_for(document, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var node = null;
          var start_time = new Date();
          var resolver = function(resolve) {
            node = AllDomHandles[#{document.handle}].window.document.querySelector("#{js_escaped_selector}");
            if (node) {
              var node_handle = RegisterElementHandle(node);
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              LastResult = {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
              resolve(true);
            }
            else if ((new Date() - start_time) > #{@jsdom_timeout}) { resolve(true); }
            else { setTimeout(resolver, #{@jsdom_reaction_timeout}, resolve) }
          };
          var promise = new Promise(function(resolve, reject){ resolver(resolve); });
          await promise;
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def document_wait_for_xpath(document, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var node = null;
          var start_time = new Date();
          var resolver = function(resolve) {
            var window = AllDomHandles[#{document.handle}].window;
            var document = window.document;
            var xpath_result = document.evaluate("#{js_escaped_query}", document, null, window.XPathResult.FIRST_ORDERED_NODE_TYPE, null);
            node = xpath_result.singleNodeValue;
            if (node) {
              var node_handle = RegisterElementHandle(node);
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              LastResult = {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
              resolve(true);
            }
            else if ((new Date() - start_time) > #{@jsdom_timeout}) { resolve(true); }
            else { setTimeout(resolver, #{@jsdom_reaction_timeout}, resolve) }
          };
          var promise = new Promise(function(resolve, reject){ resolver(resolve); });
          await promise;
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
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
        @context.eval "AllElementHandles[#{node.handle}].textContent"
      end

      def node_click(node, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # raise Isomorfeus::Pupppetmaster::InvalidActionError.new(:click) unless visible?
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        @context.exec <<~JAVASCRIPT
          var options = {button: 0, bubbles: true, cancelable: true};
          var window = AllDomHandles[#{node.document.handle}].window;
          var modifiers = #{modifiers};
          if (modifiers.includes('meta')) { options['metaKey'] = true; }
          if (modifiers.includes('control')) { options['ctrlKey'] = true; }
          if (modifiers.includes('shift')) { options['shiftKey'] = true; }
          if (modifiers.includes('alt')) { options['altKey'] = true; }
          var x = #{x ? x : 'null'};
          var y = #{y ? y : 'null'};
          if (x && y) {
            options['clientX'] = x;
            options['clientY'] = y;
          } 
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('mousedown', options));
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('mouseup', options));
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('click', options));
        JAVASCRIPT
      end

      def node_disabled?(node)
        @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{node.document.handle}].window;
          var node = AllElementHandles[#{node.handle}];
          const xpath = `parent::optgroup[@disabled] | ancestor::select[@disabled] | parent::fieldset[@disabled] |
                         ancestor::*[not(self::legend) or preceding-sibling::legend][parent::fieldset[@disabled]]`;
          return node.disabled || window.document.evaluate(xpath, node, null, window.XPathResult.BOOLEAN_TYPE, null).booleanValue;
        JAVASCRIPT
      end

      def node_dispatch_event(node, name, event_type = nil, **options)
        raise ArgumentError, 'Unknown event' unless EVENTS.key?(name.to_sym) || event_type
        event_type, opts = *EVENTS[name.to_sym] if event_type.nil?
        opts.merge!(options)
        final_options = options.map { |k,v| "#{k}: '#{v}'" }
        @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{node.document.handle}].window;
          var event = new window.#{event_type}('#{name}', { #{final_options.join(', ')} });
          AllElementHandles[#{node.handle}].dispatchEvent(event);
        JAVASCRIPT
      end

      def node_double_click(node, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        # offset: { x: int, y: int }
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        @context.exec <<~JAVASCRIPT
          var options = {button: 0, bubbles: true, cancelable: true};
          var window = AllDomHandles[#{node.document.handle}].window;
          var modifiers = #{modifiers};
          if (modifiers.includes('meta')) { options['metaKey'] = true; }
          if (modifiers.includes('control')) { options['ctrlKey'] = true; }
          if (modifiers.includes('shift')) { options['shiftKey'] = true; }
          if (modifiers.includes('alt')) { options['altKey'] = true; }
          var x = #{x ? x : 'null'};
          var y = #{y ? y : 'null'};
          if (x && y) {
            options['clientX'] = x;
            options['clientY'] = y;
          } 
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('mousedown', options));
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('mouseup', options));
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('dblclick', options));
        JAVASCRIPT
      end

      def node_drag_to(node, other_node)
        # TODO
        if node[:draggable]
          await <<~JAVASCRIPT
            var window = AllDomHandles[#{node.document.handle}].window;
            window.document.addEventListener('mousedown', event => {
              window.jsdom_mousedown_prevented = event.defaultPrevented;
            }, { once: true, passive: true });
          JAVASCRIPT
          # TODO use scrollIntoView once chromium bug is fixed
          # https://bugs.chromium.org/p/chromium/issues/detail?id=939740&can=2&start=0&num=100&q=mousemove%20scrollintoview&colspec=ID%20Type%20Status%20Priority%20Milestone%20Owner%20Summary&groupby=&sort=
          await <<~JAVASCRIPT
            var window = AllDomHandles[#{node.document.handle}].window;
            var node = AllElementHandles[#{node.handle}];
            var other_node = AllElementHandles[#{other_node.handle}];
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
              node.dispatchEvent(new window.MouseEvent('mousemove', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
              setTimeout(function(){
                node.dispatchEvent(new window.MouseEvent('mousedown', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                if (window.jsdom_mousedown_prevented) {
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
                    node.dispatchEvent(new window.MouseEvent('mousemove', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                    setTimeout(function(){
                      node.dispatchEvent(new window.MouseEvent('mouseup', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                    }, #{@jsdom_reaction_timeout/2});
                  }, #{@jsdom_reaction_timeout});
                } else {
                  var dt = new window.DataTransfer();
                  if (node.tagName == 'A'){ dt.setData('text/uri-list', node.href); dt.setData('text', node.href); }
                  if (node.tagName == 'IMG'){ dt.setData('text/uri-list', node.src); dt.setData('text', node.src); }
                  var opts = { cancelable: true, bubbles: true, dataTransfer: dt };
                  var dragEvent = new window.DragEvent('dragstart', opts);
                  node.dispatchEvent(dragEvent);
                  n = other_node;
                  top = n.offsetTop; left = n.offsetLeft; width = n.offsetWidth; height = n.offsetHeight;          
                  while(n.offsetParent) { n = n.offsetParent; top += n.offsetTop; left += n.offsetLeft; }
                  var node_in_view = (top >= window.pageYOffset && left >= window.pageXOffset &&
                  (top + height) <= (window.pageYOffset + window.innerHeight) && (left + width) <= (window.pageXOffset + window.innerWidth));
                  if (!node_in_view) { other_node.scrollTo(0,0); };
                  setTimeout(function(){
                    var rect = node.getBoundingClientRect()
                    var node_center = new window.DOMPoint((rect.left + rect.right)/2, (rect.top + rect.bottom)/2);
                    var other_rect = other_node.getBoundingClientRect();
                    var other_point = new window.DOMPoint((other_rect.left + other_rect.right)/2, (other_rect.top + other_rect.bottom)/2);
                    var entry_point = null;
                    var slope = (other_point.y - other_point.y) / (other_point.x - node_center.x);
                    if (other_point.x <= other_point.x) { // left side
                      var minXy = slope * (other_rect.left - node_center.x) + node_center.y;
                      if (other_rect.top <= minXy && minXy <= other_rect.bottom) { entry_point = new window.DOMPoint(other_rect.left, minXy); }
                    }
                    if (node_center.x >= other_point.x) { // right side
                      var maxXy = slope * (other_rect.right - node_center.x) + node_center.y;
                      if (other_rect.top <= maxXy && maxXy <= other_rect.bottom) { entry_point = new window.DOMPoint(other_rect.right, maxXy); }
                    }
                    if (node_center.y <= other_point.y) { // top side
                      var minYx = (other_point.top - node_center.y) / slope + node_center.x;
                      if (other_rect.left <= minYx && minYx <= other_rect.right) { entry_point = new window.DOMPoint(minYx, other_rect.top); }
                    }
                    if (node_center.y >= other_point.y) { // bottom side
                      var maxYx = (other_rect.bottom - node_center.y) / slope + node_center.x;
                      if (other_rect.left <= maxYx && maxYx <= other_rect.right) { entry_point = new window.DOMPoint(maxYx, other_rect.bottom); }
                    }
                    if (!entry_point) {
                      entry_point = new window.DOMPoint(node_center.x, node_center.y);
                    }
                    var drag_over_event = new window.DragEvent('dragover', {clientX: entry_point.x, clientY: entry_point.y, bubbles: true, cancelable: true});
                    other_node.dispatchEvent(drag_over_event);
                    var other_center = new window.DOMPoint((other_rect.left + other_rect.right)/2, (other_rect.top + other_rect.bottom)/2);
                    drag_over_event = new window.DragEvent('dragover', {clientX: targetCenter.x, clientY: targetCenter.y, bubbles: true, cancelable: true});
                    other_node.dispatchEvent(drag_over_event);
                    other_node.dispatchEvent(new window.DragEvent('dragleave', {bubbles: true, cancelable: true}));
                    if (drag_over_event.defaultPrevented) {
                      other_node.dispatchEvent(new window.DragEvent('drop', {bubbles: true, cancelable: true}));
                    }
                    node.dispatchEvent(new window.DragEvent('dragend', {bubbles: true, cancelable: true}));
                    client_rect = other_node.getBoundingClientRect();
                    x = (client_rect.left + (client_rect.width / 2));
                    y = (client_rect.top + (client_rect.height / 2));
                    node.dispatchEvent(new window.MouseEvent('mouseup', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
                  }, #{@jsdom_reaction_timeout});
                }
              }, #{@jsdom_reaction_timeout/2});
            }, #{@jsdom_reaction_timeout});
          JAVASCRIPT
          sleep (@reaction_timeout * 3) + 0.2
        else
          await <<~JAVASCRIPT
            var window = AllDomHandles[#{node.document.handle}].window;
            var node = AllElementHandles[#{node.handle}];
            var other_node = AllElementHandles[#{other_node.handle}];
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
              node.dispatchEvent(new window.MouseEvent('mousemove', {clientX: x, clientY: y, bubbles: true, cancelable: true}));
              setTimeout(function() {
                node.dispatchEvent(new window.MouseEvent('mousedown', {button: 0, buttons: 1, clientX: x, clientY: y, bubbles: true, cancelable: true}));
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
                  node.dispatchEvent(new window.MouseEvent('mousemove', {button: 0, buttons: 1, clientX: x, clientY: y, bubbles: true, cancelable: true}));
                  setTimeout(function() {
                    node.dispatchEvent(new window.MouseEvent('mouseup', {button: 0, buttons: 1, clientX: x, clientY: y, bubbles: true, cancelable: true}));
                  }, #{@jsdom_reaction_timeout/2});
                }, #{@jsdom_reaction_timeout});
              }, #{@jsdom_reaction_timeout/2});
            }, #{@jsdom_reaction_timeout});
          JAVASCRIPT
          sleep (@reaction_timeout * 3) + 0.2
        end
      end

      def node_equal(node, other_node)
        @context.eval "AllElementHandles[#{node.handle}] === AllElementHandles[#{other_node.handle}]"
      end

      def node_execute_script(node, script, *args)
        # TODO
        await <<~JAVASCRIPT
          var node_handle = #{node.handle};
          await AllElementHandles[node_handle].executionContext().evaluateHandle((node, arguments) => {
            arguments.unshift(node);
            #{script}
          }, AllElementHandles[node_handle], #{args[1..-1]});
        JAVASCRIPT
      end

      def node_evaluate_script(node, script, *args)
        # TODO
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
        node_data = @context.exec <<~JAVASCRIPT
          var node = AllElementHandles[#{node.handle}].querySelector("#{js_escaped_selector}");
          if (node) {
            var node_handle = RegisterElementHandle(node);
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            return {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
          }
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(selector)
        end
      rescue ExecJS::RuntimeError => e
        raise determine_error(e.message)
      end

      def node_find_all(node, selector)
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = @context.exec <<~JAVASCRIPT
          var node_array = AllElementHandles[#{node.handle}].querySelectorAll("#{js_escaped_selector}");
          var node_data_array = [];
          if (node_array) {
            for (var i=0; i<node_array.length; i++) {
              var node_handle = RegisterElementHandle(node_array[i]);
              var tag = node_array[i].tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node_array[i].getAttribute('type'); }
              node_data_array.push({handle: node_handle, tag: tag, type: type, content_editable: node_array[i].isContentEditable});
            }
          }
          return node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        end
      end

      def node_find_all_xpath(node, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data_array = @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{node.document.handle}].window;
          var document = window.document;
          var xpath_result = document.evaluate("#{js_escaped_query}", AllElementHandles[#{node.handle}], null, window.XPathResult.ORDERED_NODE_ITERATOR_TYPE, null);
          var node;
          var node_data_array = [];
          while (node = xpath_result.iterateNext) {
            var node_handle = RegisterElementHandle(node);
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            node_data_array.push({handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable});
          }  
          return node_data_array;
        JAVASCRIPT
        node_data_array.map do |node_data|
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        end
      end

      def node_find_xpath(node, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{node.document.handle}].window;
          var document = window.document;
          var xpath_result = document.evaluate("#{js_escaped_query}", AllElementHandles[#{node.handle}], null, window.XPathResult.FIRST_ORDERED_NODE_TYPE, null);
          var node = xpath_result.singleNodeValue;
          if (node) {
            var node_handle = RegisterElementHandle(node);
            var tag = node.tagName.toLowerCase();
            var type = null;
            if (tag === 'input') { type = node.getAttribute('type'); }
            return {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
          }
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, node.document, node_data)
        else
          raise Isomorfeus::Puppetmaster::ElementNotFound.new(query)
        end
      rescue ExecJS::ProgramError => e
        raise determine_error('invalid xpath query')
      end

      def node_focus(node)
        await "await AllElementHandles[#{node.handle}].focus();"
      end

      def node_get_attribute(node, attribute)
        attribute = attribute.to_s
        if !(attribute.start_with?('aria-') || attribute.start_with?('data-'))
          attribute = attribute.camelize(:lower)
        end
        @context.eval "AllElementHandles[#{node.handle}].getAttribute('#{attribute}')"
      end

      def node_hover(node)
        @context.exec "AllElementHandles[#{node.handle}].hover()"
      end

      def node_html(node)
        @context.eval("AllElementHandles[#{node.handle}].outerHTML")
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

      def node_render_base64(_node, **_options)
        raise Isomorfeus::Puppetmaster::NotSupported
      end

      def node_right_click(node, x: nil, y: nil, modifiers: nil)
        # modifier_keys: :alt, :control, :meta, :shift
        modifiers = [modifiers] if modifiers.is_a?(Symbol)
        modifiers = [] unless modifiers
        modifiers = modifiers.map {|key| key.to_s.camelize(:lower) }
        await <<~JAVASCRIPT
          var options = {button: 2, bubbles: true, cancelable: true};
          var window = AllDomHandles[#{node.document.handle}].window;
          var modifiers = #{modifiers};
          if (modifiers.includes('meta')) { options['metaKey'] = true; }
          if (modifiers.includes('control')) { options['ctrlKey'] = true; }
          if (modifiers.includes('shift')) { options['shiftKey'] = true; }
          if (modifiers.includes('alt')) { options['altKey'] = true; }
          var x = #{x ? x : 'null'};
          var y = #{y ? y : 'null'};
          if (x && y) {
            options['clientX'] = x;
            options['clientY'] = y;
          } 
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('mousedown', options));
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('mouseup', options));
          AllElementHandles[#{node.handle}].dispatchEvent(new window.MouseEvent('contextmenu', options));
        JAVASCRIPT
      end

      def node_inner_html(node)
        @context.eval("AllElementHandles[#{node.handle}].innerHTML")
      end

      def node_save_screenshot(_node, _path, **_options)
        raise Isomorfeus::Puppetmaster::NotSupported
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
        cjs = <<~JAVASCRIPT
          AllElementHandles[#{node.handle}].focus();
          var window = AllDomHandles[#{node.document.handle}].window;
          var events = [];
          var chars = '';
          var tag = AllElementHandles[#{node.handle}].tagName;
        JAVASCRIPT
        # new KeyboardEvent("keydown", { bubbles: true, cancelable: true, key: character.charCodeAt(0), char: character, shiftKey: false });
        top_modifiers = []
        keys.each do |key|
          if key.is_a?(String)
            key.each_char do |c|
              shift = !! /[[:upper:]]/.match(c)
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{shift || need_shift?(top_modifiers)}}));
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{shift || need_shift?(top_modifiers)}}));
              JAVASCRIPT
              # hack to make input actually happen, sort of
              cjs << <<~JAVASCRIPT
                chars = chars + '#{(shift || need_shift?(top_modifiers)) ? c.upcase : c}';
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{shift || need_shift?(top_modifiers)}}));
              JAVASCRIPT
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
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
            else
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
                  altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
                  shiftKey: #{need_shift?(top_modifiers)}}));
              JAVASCRIPT
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
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                else
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{need_shift?(modifiers)}}));
                  JAVASCRIPT
                end
              elsif k.is_a?(String)
                k.each_char do |c|
                  shift = !! /[[:upper:]]/.match(c)
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keydown', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{shift || need_shift?(modifiers)}}));
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keypress', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{shift || need_shift?(modifiers)}}));
                  JAVASCRIPT
                  # hack to make input actually happen, sort of
                  cjs << <<~JAVASCRIPT
                    chars = chars + '#{(shift || need_shift?(modifiers)) ? c.upcase : c}';
                  JAVASCRIPT
                  cjs << <<~JAVASCRIPT
                    events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{c}'.charCodeAt(0), char: '#{c}',
                      altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                      shiftKey: #{shift || need_shift?(modifiers)}}));
                  JAVASCRIPT
                end
              end
            end
            modifiers.reverse.each do |k|
              cjs << <<~JAVASCRIPT
                events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{k.to_s.camelize}', code: '#{k.to_s.camelize}',
                  altKey: #{need_alt?(modifiers)}, ctrlKey: #{need_control?(modifiers)}, metaKey: #{need_meta?(modifiers)},
                  shiftKey: #{need_shift?(modifiers)}}));
              JAVASCRIPT
            end
          end
        end
        top_modifiers.reverse.each do |key|
          cjs << <<~JAVASCRIPT
            events.push(new window.KeyboardEvent('keyup', { bubbles: true, cancelable: true, key: '#{key.to_s.camelize}', code: '#{key.to_s.camelize}',
              altKey: #{need_alt?(top_modifiers)}, ctrlKey: #{need_control?(top_modifiers)}, metaKey: #{need_meta?(top_modifiers)},
              shiftKey: #{need_shift?(top_modifiers)}}));
          JAVASCRIPT
        end
        cjs << <<~JAVASCRIPT
          for (i=0; i<events.length; i++) {
            AllElementHandles[#{node.handle}].dispatchEvent(events[i]);
          }
          if (tag === 'INPUT' || tag === 'TEXTAREA') {AllElementHandles[#{node.handle}].value = chars }
        JAVASCRIPT
        @context.exec cjs
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
        @context.exec <<~JAVASCRIPT
          var node = AllElementHandles[#{node.handle}];
          if (node.tagName == "SELECT" && node.multiple) {
            var result = []
            for (let i = 0, len = node.children.length; i < len; i++) {
              var option = node.children[i];
              if (option.selected) { result.push(option.value); }
            }
            return result;
          } else if (node.isContentEditable) { return node.textContent; }
          else { return node.value; }
        JAVASCRIPT
      end

      def node_value=(node, value)
        raise Isomorfeus::Puppetmaster::ReadOnlyElementError if node.readonly?
        real_value = "`#{value}`"
        @context.exec <<~JAVASCRIPT
          var window = AllDomHandles[#{node.document.handle}].window;
          var node = AllElementHandles[#{node.handle}];
          var value = #{real_value};
          if (node.maxLength >= 0) { value = value.substr(0, node.maxLength); }
          node.dispatchEvent(new window.FocusEvent("focus",{bubbles: true, cancelable: true}));
          var tag_name = node.tagName.toLowerCase();
          if (tag_name === 'input') {
            node.value = '';
            if (node.type === "number" || node.type === "date") { 
              for (var i = 0; i < value.length; i++) {
                node.dispatchEvent(new window.KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                node.dispatchEvent(new window.KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                node.dispatchEvent(new window.KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
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
                node.dispatchEvent(new window.KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                node.value = node.value + value[i];
                node.dispatchEvent(new window.KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                node.dispatchEvent(new window.KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
              }
            } else if (node.type === 'checkbox' || node.type === 'radio') { node.checked = value; }
            else {
              for (var i = 0; i < value.length; i++) {
                node.dispatchEvent(new window.KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                node.value = node.value + value[i];
                node.dispatchEvent(new window.KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
                node.dispatchEvent(new window.KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
              }
            }
          } else if (tag_name === 'textarea') {
            for (var i = 0; i < value.length; i++) {
              node.dispatchEvent(new window.KeyboardEvent("keydown", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
              node.value = node.value + value[i];
              node.dispatchEvent(new window.KeyboardEvent("keyup", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
              node.dispatchEvent(new window.KeyboardEvent("keypress", {key: value[i], code: value.charCodeAt(0), bubbles: true, cancelable: true}));
            }
          }
        JAVASCRIPT
        real_value
      end

      def node_visible_text(node)
        # if node is AREA, check visibility of relevant image
        text = @context.exec <<~JAVASCRIPT
          var node = AllElementHandles[#{node.handle}];
          var window = AllDomHandles[#{node.document.handle}].window
          var temp_node = node;
          var mapName, style;
          if (node.tagName === "AREA") {
            mapName = document.evaluate("./ancestor::map/@name", node, null, XPathResult.STRING_TYPE, null).stringValue;
            temp_node = document.querySelector('img[usemap="#${mapName}"]');
            if (temp_node == null) { return ''; }
          } else {
            temp_node = node;
            while (temp_node) {
              style = window.getComputedStyle(node);
              if (style.display === "none" || style.visibility === "hidden" || parseFloat(style.opacity) === 0) { return ''; }
              temp_node = temp_node.parentElement;
            }
          }
          if (node.nodeName == "TEXTAREA" || node instanceof window.SVGElement) { return node.textContent; }
          else { return (node.innerText ? node.innerText : node.textContent); }
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
        js_escaped_selector = selector.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var start_time = new Date();
          var resolver = function(resolve) {
            var node = AllElementHandles[#{node.handle}].querySelector("#{js_escaped_selector}");
            if (node) {
              var node_handle = RegisterElementHandle(node);
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              LastResult = {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
              resolve(true);
            }
            else if ((new Date() - start_time) > #{@jsdom_timeout}) { resolve(true); }
            else { setTimeout(resolver, #{@jsdom_reaction_timeout}, resolve) }
          };
          var promise = new Promise(function(resolve, reject){ resolver(resolve); });
          await promise;
        JAVASCRIPT
        if node_data
          node_data[:css_selector] = selector
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      def node_wait_for_xpath(node, query)
        js_escaped_query = query.gsub('\\', '\\\\\\').gsub('"', '\"')
        node_data = await <<~JAVASCRIPT
          var start_time = new Date();
          var resolver = function(resolve) {
            var window = AllDomHandles[#{document.handle}].window;
            var document = window.document;
            var xpath_result = document.evaluate("#{js_escaped_query}", AllElementHandles[#{node.handle}], null, window.XPathResult.FIRST_ORDERED_NODE_TYPE, null);
            var node = xpath_result.singleNodeValue;
            if (node) {
              var node_handle = RegisterElementHandle(node);
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              LastResult = {handle: node_handle, tag: tag, type: type, content_editable: node.isContentEditable};
              resolve(true);
            }
            else if ((new Date() - start_time) > #{@jsdom_timeout}) { resolve(true); }
            else { setTimeout(resolver, #{@jsdom_reaction_timeout}, resolve) }
          };
          var promise = new Promise(function(resolve, reject){ resolver(resolve); });
          await promise;
        JAVASCRIPT
        if node_data
          node_data[:xpath_query] = query
          Isomorfeus::Puppetmaster::Node.new_by_tag(self, document, node_data)
        end
      end

      private

      def need_alt?(modifiers)
        (modifiers & %i[alt alt_left alt_right]).size > 0
      end

      def need_control?(modifiers)
        (modifiers & %i[control control_left control_rigth]).size > 0
      end

      def need_meta?(modifiers)
        (modifiers & %i[meta meta_left meta_right]).size > 0
      end

      def need_shift?(modifiers)
        (modifiers & %i[shift shift_left shift_right]).size > 0
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

      def determine_error(message)
        if message.include?('Error: certificate has expired')
          Isomorfeus::Puppetmaster::CertificateError.new(message) unless @ignore_https_errors
        elsif message.include?('Error: getaddrinfo ENOTFOUND')
          Isomorfeus::Puppetmaster::DNSError.new(message)
        elsif message.include?('Unknown key: ')
          Isomorfeus::Puppetmaster::KeyError.new(message)
        elsif message.include?('Execution context was destroyed, most likely because of a navigation.')
          Isomorfeus::Puppetmaster::ExecutionContextError.new(message)
        elsif message.include?('Unable to find ')
          Isomorfeus::Puppetmaster::ElementNotFound.new(message)
        elsif (message.include?('SyntaxError:') && (message.include?('unknown pseudo-class selector') || message.include?('is not a valid selector'))) || message.include?('invalid xpath query')
          Isomorfeus::Puppetmaster::DOMException.new(message)
        else
          Isomorfeus::Puppetmaster::JavaScriptError.new(message)
        end
      end

      def execution_finished?
        @context.eval 'LastExecutionFinished'
      end

      def get_result
        res, err_msg = @context.eval 'GetLastResult()'
        raise determine_error(err_msg) if err_msg
        res
      end

      def jsdom_launch
        <<~JAVASCRIPT
          const canvas = require('canvas')
          const jsdom = require('jsdom');
          const Cookie = jsdom.toughCookie.Cookie;
          const MemoryCookieStore = jsdom.toughCookie.MemoryCookieStore;
          const { JSDOM } = jsdom;
          
          const JSDOMOptions = {pretendToBeVisual: true, resources: 'usable', runScripts: 'dangerously'};

          var LastResponse = null;
          var LastResult = null;
          var LastErr = null;
          var LastExecutionFinished = false;
          var LastHandleId = 0;
  
          var AllDomHandles = {};
          var AllElementHandles = {};
          var AllConsoleHandles = {};
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
            AllElementHandles[LastHandleId] = element_handle;
            return LastHandleId; 
          };
  
          const RegisterElementHandleArray = function(element_handle_array) {
            var registered_handles = [];
            element_handle_array.forEach(function(handle){
              registered_handles.push(RegisterElementHandle(handle));
            });
            return registered_handles;
          };
  
          const RegisterCon = function(con) {
            var entries = Object.entries(ConsoleMessages);
            for(var i = 0; i < entries.length; i++) { 
              if (entries[i][1] === con) { return entries[i][0]; }
            }
            LastHandleId++;
            AllConsoleHandles[LastHandleId] = con;
            ConsoleMessages[LastHandleId] = [];
            return LastHandleId;
          };
          const RegisterDom = function(dom, handle_id) {
            var entries = Object.entries(AllDomHandles);
            for(var i = 0; i < entries.length; i++) { 
              if (entries[i][1] === dom) { return entries[i][0]; }
            }
            AllDomHandles[handle_id] = dom;
            return handle_id;
          };
  
          (async () => {
            try {
              var con = new jsdom.VirtualConsole();
              var jar = new jsdom.CookieJar(new MemoryCookieStore(), {rejectPublicSuffixes: false, looseMode: true});
              var handle_id = RegisterCon(con);
              con.on('error', (msg) => { ConsoleMessages[handle_id].push({level: 'error', location: '', text: msg}); });
              con.on('warn', (msg) => { ConsoleMessages[handle_id].push({level: 'warn', location: '', text: msg}); });
              con.on('info', (msg) => { ConsoleMessages[handle_id].push({level: 'info', location: '', text: msg}); });
              con.on('log', (msg) => { ConsoleMessages[handle_id].push({level: 'dir', location: '', text: msg}); });
              con.on('debug', (msg) => { ConsoleMessages[handle_id].push({level: 'dir', location: '', text: msg}); });
              var dom = new JSDOM('', Object.assign({}, JSDOMOptions, { virtualConsole: con }));
              var browser = dom.window.navigator.userAgent;
              LastResult = [RegisterDom(dom, handle_id), browser];
              LastExecutionFinished = true;
            } catch (err) {
              LastErr = err;
              LastExecutionFinished = true;
            }
          })();
        JAVASCRIPT
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