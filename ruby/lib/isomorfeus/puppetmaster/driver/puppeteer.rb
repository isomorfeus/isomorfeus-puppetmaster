module Isomorfeus
  module Puppetmaster
    module Driver
      class Puppeteer
        include Isomorfeus::Puppetmaster::Driver::PuppeteerDocument
        include Isomorfeus::Puppetmaster::Driver::PuppeteerNode

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
                              when :chrome then chromium_require
                              when :chromium then chromium_require
                              else
                                raise "Browser type #{@browser_type} not supported!"
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
                var target = page.target();
                var cdp_session = await target.createCDPSession();
                await cdp_session.send('Page.setDownloadBehavior', {behavior: 'allow', downloadPath: '#{Isomorfeus::Puppetmaster.download_path}'});
                if (#{@url_blacklist}.length > 0) { await cdp_session.send('Network.setBlockedURLs', {urls: #{@url_blacklist}}); }
                await cdp_session.detach();
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
end
