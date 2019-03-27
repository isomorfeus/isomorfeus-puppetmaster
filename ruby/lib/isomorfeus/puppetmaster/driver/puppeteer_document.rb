module Isomorfeus
  module Puppetmaster
    module Driver
      module PuppeteerDocument
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
      end
    end
  end
end
