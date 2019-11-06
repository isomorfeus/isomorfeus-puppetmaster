module Isomorfeus
  module Puppetmaster
    module Driver
      module JsdomDocument
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
            var name = node.nodeName;
            var tag = node.tagName.toLowerCase();
            return {handle: node_handle, name: name, tag: tag, type: null, content_editable: node.isContentEditable};
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
          result_hash = {}
          result.each do |cookie|
            cookie['name'] = cookie['key']
            cookie['expires'] = DateTime.parse(cookie['expires']).to_time if cookie.has_key?('expires')
            result_hash[cookie['name']] = Isomorfeus::Puppetmaster::Cookie.new(cookie)
          end
          result_hash
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
              "var arguments = #{ "#{args}".gsub('"', '\"') };" +
              "#{script.strip.gsub('\\', '\\\\\\').gsub('"', '\"').gsub("\n", "\\n")}"
            )
          JAVASCRIPT
        rescue ExecJS::ProgramError => e
          raise determine_error(e.message)
        end

        def document_execute_script(document, script, *args)
          @context.eval <<~JAVASCRIPT
            AllDomHandles[#{document.handle}].window.eval(
              "(function() { var arguments = #{ "#{args}".gsub('"', '\"') };" +
              "#{script.strip.gsub('\\', '\\\\\\').gsub('"', '\"').gsub("\n", "\\n")}" +
              "})()" 
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
              var tag = node.tagName ? node.tagName.toLowerCase() : '';
              var name = node.nodeName;
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return {handle: node_handle, name: name, tag: tag, type: type, content_editable: node.isContentEditable};
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
                var node = node_array[i];
                var node_handle = RegisterElementHandle(node_array[i]);
                var tag = node.tagName ? node.tagName.toLowerCase() : '';
                var name = node.nodeName;
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                node_data_array.push({handle: node_handle, name: name, tag: tag, type: type, content_editable: node.isContentEditable});
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
            while (node = xpath_result.iterateNext()) {
              var node_handle = RegisterElementHandle(node);
              var tag = node.tagName ? node.tagName.toLowerCase() : '';
              var name = node.nodeName;
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              node_data_array.push({handle: node_handle, name: name, tag: tag, type: type, content_editable: node.isContentEditable});
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
              var tag = node.tagName ? node.tagName.toLowerCase() : '';
              var name = node.nodeName;
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return {handle: node_handle, name: name, tag: tag, type: type, content_editable: node.isContentEditable};
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
            var name = node.nodeName;
            var tag = node.tagName.toLowerCase();
            return {handle: node_handle, name: name, tag: tag, type: null, content_editable: node.isContentEditable};
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
                var name = node.nodeName;
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                LastResult = {handle: node_handle, name: name, tag: tag, type: type, content_editable: node.isContentEditable};
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
                var name = node.nodeName;
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                LastResult = {handle: node_handle, name: name, tag: tag, type: type, content_editable: node.isContentEditable};
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
      end
    end
  end
end
