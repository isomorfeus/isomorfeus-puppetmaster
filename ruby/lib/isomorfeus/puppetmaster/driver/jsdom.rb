module Isomorfeus
  module Puppetmaster
    module Driver
      class Jsdom
        include Isomorfeus::Puppetmaster::Driver::JsdomDocument
        include Isomorfeus::Puppetmaster::Driver::JsdomNode

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
          @canvas = @options.delete(:canvas) { false }
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

        ##### frame, all todo

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
              var name = node.nodeName;
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [name, tag, type];
            }, AllElementHandles[#{frame.handle}]);
            LastResult = {handle: node_handle, name: tt[0], tag: tt[1], type: tt[2]};
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
              var name = node.nodeName;
              var tag = node.tagName.toLowerCase();
              var type = null;
              if (tag === 'input') { type = node.getAttribute('type'); }
              return [name, tag, type];
            }, AllElementHandles[#{frame.handle}]);
            LastResult = {handle: node_handle, name: tt[0], tag: tt[1], type: tt[2]};
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
          elsif message.include?('Error: getaddrinfo')
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
            #{"const canvas = require('canvas');" if @canvas}
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
    
                if (err) { return [null, err.toString() + "\\n" + err.stack]; }
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
end
