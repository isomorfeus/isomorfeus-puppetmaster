module Isomorfeus
  module Puppetmaster
    class Document
      extend Isomorfeus::Puppetmaster::SelfForwardable

      document_forward %i[
        all_text
        accept_alert
        accept_confirm
        accept_leave_page
        accept_prompt
        body
        bring_to_front
        clear_authentication_credentials
        clear_cookies
        clear_extra_headers
        clear_url_blacklist
        click
        close
        cookies
        console
        dismiss_confirm
        dismiss_leave_page
        dismiss_prompt
        dispatch_event
        double_click
        evaluate_script
        execute_script
        find
        find_all
        find_all_xpath
        find_xpath
        head
        html
        open_new_document
        remove_cookie
        render_base64
        reset_user_agent
        right_click
        save_pdf
        save_screenshot
        scroll_by
        scroll_to
        set_authentication_credentials
        set_cookie
        set_extra_headers
        set_url_blacklist
        set_user_agent
        title
        url
        user_agent
        viewport_maximize
        viewport_resize
        viewport_size
        wait_for
        wait_for_xpath
      ]

      attr_reader :handle, :response

      def initialize(driver, handle, response)
        @driver = driver
        @handle = handle
        @response = response
        ObjectSpace.define_finalizer(self, @driver.class.document_handle_disposer(@driver, @handle))
      end

      def browser
        @driver.browser
      end

      def await_ruby(ruby_source = '', &block)
        ruby_source = Isomorfeus::Puppetmaster.block_source_code(&block) if block_given?
        ruby_source = "#{ruby_source}.then { |result| $promise_result = result; $promise_resolved = true }.fail { |result| $promise_result = result; $promise_resolved = true }"
        compiled_ruby = compile_ruby_source(ruby_source)
        if compiled_ruby.start_with?('/*')
          start_of_code = compiled_ruby.index('*/') + 3
          compiled_ruby = compiled_ruby[start_of_code..-1]
        end
        evaluate_script <<~JAVASCRIPT
          (function(){
            fun = function() {
              if (Opal) {
                Opal.gvars.promise_resolved = false;
                Opal.await_ruby_exception = null;
                try {
                  return #{compiled_ruby}
                } catch (e) {
                  Opal.await_ruby_exception = e;
                  Opal.gvars.promise_resolved = true;
                }
              } else {
                setTimeout(fun, 100);
              }
            }
            fun();
          })()
        JAVASCRIPT
        have_result = false
        start = Time.now
        until have_result do
          raise "await_ruby: execution timed out! Is Opal available?" if (Time.now - start) > 30
          have_result = evaluate_script 'Opal ? Opal.gvars.promise_resolved : null'
          sleep 0.1 unless have_result
        end
        result, exception = execute_script <<~JAVASCRIPT
          var result;
          var exception = false;
          if (Opal.await_ruby_exception) {
            var e = Opal.await_ruby_exception;
            exception = { message: e.message, name: e.name, stack: e.stack }
          } else if (Opal.gvars.promise_result['$respond_to?']('is_a?') && Opal.gvars.promise_result['$is_a?'](Opal.Exception)) {
            let r = Opal.gvars.promise_result;
            exception = { message: r.$message(), name: r.$class().$name(), stack: r.$backtrace() }
          } else if (Opal.gvars.promise_result['$respond_to?']('to_n')) { 
            result = Opal.gvars.promise_result.$to_n()
          } else { result = Opal.gvars.promise_result };
          delete Opal.gvars.promise_result;
          delete Opal.gvars.promise_resolved;
          return [result, exception];
        JAVASCRIPT
        if exception
          e = Isomorfeus::Puppetmaster::Error.new("#{exception['name']}: #{exception['message']}")
          e.set_backtrace(exception['stack'])
          raise e
        end
        result
      end

      def evaluate_ruby(ruby_source = '', &block)
        ruby_source = Isomorfeus::Puppetmaster.block_source_code(&block) if block_given?
        compiled_ruby = compile_ruby_source(ruby_source)
        if compiled_ruby.start_with?('/*')
          start_of_code = compiled_ruby.index('*/') + 3
          compiled_ruby = compiled_ruby[start_of_code..-1]
        end
        evaluate_script <<~JAVASCRIPT
          (function(){
            return #{compiled_ruby}
          })()
        JAVASCRIPT
      end

      def evaluate_with_opal(ruby_source = '', &block)
        ruby_source = Isomorfeus::Puppetmaster.block_source_code(&block) if block_given?
        compiled_ruby = compile_ruby_source(ruby_source)
        if compiled_ruby.start_with?('/*')
          start_of_code = compiled_ruby.index('*/') + 3
          compiled_ruby = compiled_ruby[start_of_code..-1]
        end
        evaluate_script <<~JAVASCRIPT
          (function(){
            if (typeof Opal === "undefined") {
              #{Isomorfeus::Puppetmaster.opal_prelude}
            }
            return #{compiled_ruby}
          })()
        JAVASCRIPT
      end

      def go_back
        @response = @driver.document_go_back(self)
        self
      end

      def go_forward
        @response = @driver.document_go_forward(self)
        self
      end

      def goto(uri)
        @response = @driver.document_goto(self, uri)
        self
      end
      alias_method :visit, :goto

      def has_content?(content, **options)
        body.has_content?(content, options)
      end

      def has_css?(selector, **options)
        body.has_css?(selector, options)
      end

      def has_current_path?(other_path)
        path == other_path
      end

      def has_text?(text, **options)
        body.has_text?(text, options)
      end

      def has_xpath?(query, **options)
        body.has_xpath?(query, options)
      end

      def isomorphic(ruby_source = '', &block)
        ruby_source = Isomorfeus::Puppetmaster.block_source_code(&block) if block_given?
        Isomorfeus::Puppetmaster.served_app.on_server(ruby_source)
        evaluate_ruby(ruby_source)
      end

      def isomorphic_with_opal(ruby_source = '', &block)
        ruby_source = Isomorfeus::Puppetmaster.block_source_code(&block) if block_given?
        Isomorfeus::Puppetmaster.served_app.on_server(ruby_source)
        evaluate_with_opal(ruby_source)
      end

      def method_missing(name, *args)
        method_name = name.to_s
        if method_name.start_with?('find_by_')
          what = method_name[8..-1]
          return find("[#{what}=\"#{args.first}\"]") if %w[name type value].include?(what)
          return find_xpath("//*[text()=\"#{args.first}\"]") if what == 'content'
        elsif method_name.start_with?('has_')
          #       :has_checked_field?, #
          #       :has_content?,
          #       :has_css?,
          #       :has_field?,
          #       :has_link?,
          #       :has_select?,
          #       :has_selector?,
          #       :has_table?,
          #       :has_text?,
          #       :has_unchecked_field?,
          #       :has_xpath?,
          # :has_button?, # method_missing
        end
        super(name, *args)
      end

      def open_document_by(&block)
        open_documents = @driver.document_handles
        block.call
        new_documents = @driver.document_handles - open_documents
        raise 'Multiple documents opened' if new_documents.size > 1
        raise 'No window opened' if new_documents.size < 1
        Isomorfeus::Puppetmaster::Document.new(@driver, new_documents.first, Isomorfeus::Puppetmaster::Response.new)
      end

      def path
        URI.parse(url).path
      end

      def reload
        @response = @driver.reload(self)
      end

      def respond_to?(name, include_private = false)
        return true if %i[find_by_content find_by_name find_by_type find_by_value].include?(name)
        super(name, include_private)
      end

      # assertions
      #       :assert_current_path,
      #       :assert_no_current_path
      #       assert_title
      #       assert_no_title

      protected

      def compile_ruby_source(source_code)
        # TODO maybe use compile server
        Opal.compile(source_code, parse_comments: false)
      end
    end
  end
end
