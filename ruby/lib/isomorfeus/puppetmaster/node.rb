module Isomorfeus
  module Puppetmaster
    class Node
      SUPPORTED_HTML_ELEMENTS = %w[
        a abbr address area article aside audio
        b base bdi bdo blockquote body br button
        canvas caption cite code col colgroup
        data datalist dd del details dfn dialog div dl dt
        em embed
        fieldset figcaption figure footer form
        h1 h2 h3 h4 h5 h6 head header hr html
        i iframe img input ins
        kbd
        label legend li link
        main map mark meta meter
        nav noscript
        object ol optgroup option output
        p param picture pre progress
        q
        rp rt rtc ruby
        s samp script section select small source span strong style sub summary sup
        table tbody td template textarea tfoot th thead time title tr track
        u ul
        var video
        wbr
      ].freeze

      # https://www.w3.org/TR/SVG11/eltindex.html
      # elements listed above not mentioned a second time
      SUPPORTED_SVG_ELEMENTS = %w[
        altGlyph altGlyphDef altGlyphItem animate animateColor animateMotion animateTransform
        circle clipPath color-profile cursor
        defs desc
        ellipse
        feBlend feColorMatrix feComponentTransfer feComposite feConvolveMatrix feDiffuseLighting
        feDisplacementMap feDistantLight feFlood feFuncA feFuncB feFuncG feFuncR feGaussianBlur
        feImage feMerge feMergeNode feMorphology feOffset fePointLight feSpecularLighting
        feSpotLight feTile feTurbulence
        filter font font-face font-face-format font-face-name font-face-src font-face-uri foreignObject
        g glyph glyphRef
        hkern
        image
        line linearGradient
        marker mask metadata missing-glyph mpath
        path pattern polygon polyline
        radialGradient rect
        script set stop style svg switch symbol
        text textPath tref tspan
        use
        view vkern
      ].freeze
      SUPPORTED_HTML_AND_SVG_ELEMENTS = (SUPPORTED_HTML_ELEMENTS + SUPPORTED_SVG_ELEMENTS).freeze

      extend Isomorfeus::Puppetmaster::SelfForwardable

      node_forward %i[
        all_text
        click
        disabled?
        dispatch_event
        double_click
        drag_to
        evaluate_script
        execute_script
        find
        find_all
        find_all_xpath
        find_xpath
        focus
        hover
        in_viewport?
        render_base64
        right_click
        save_screenshot
        scroll_by
        scroll_into_view
        scroll_to
        style
        source
        type_keys
        visible_text
        visible?
        wait_for
        wait_for_xpath
      ]

      attr_reader :document, :handle, :css_selector, :name, :tag, :xpath_query

      SUPPORTED_HTML_ELEMENTS.each do |element|
        is_name = element == 'a' ? :is_link? : "is_#{element}?".to_sym
        define_method(is_name) do
          @tag == element
        end
      end

      def self.new_by_tag(driver, document, node_data)
        tag = node_data[:tag] || node_data['tag']
        case tag
        when 'iframe' then Isomorfeus::Puppetmaster::Iframe.new(driver, document, node_data)
        when 'input'
          type = node_data[:type] || node_data['type']
          case type
          when 'checkbox' then Isomorfeus::Puppetmaster::Checkbox.new(driver, document, node_data)
          when 'filechooser' then Isomorfeus::Puppetmaster::Filechooser.new(driver, document, node_data)
          when 'radiobutton' then Isomorfeus::Puppetmaster::Radiobutton.new(driver, document, node_data)
          when 'select' then Isomorfeus::Puppetmaster::Select.new(driver, document, node_data)
          else
            Isomorfeus::Puppetmaster::Input.new(driver, document, node_data)
          end
        when 'textarea' then Isomorfeus::Puppetmaster::Textarea.new(driver, document, node_data)
        else
          content_editable = node_data[:content_editable] || node_data['content_editable']
          if content_editable
            Isomorfeus::Puppetmaster::ContentEditable.new(driver, document, node_data)
          else
            Isomorfeus::Puppetmaster::Node.new(driver, document, node_data)
          end
        end
      end

      def initialize(driver, document, node_data)
        @css_selector = node_data[:css_selector] || node_data['css_selector']
        @document = document
        @driver = driver
        @handle = node_data[:handle] || node_data['handle']
        @name = node_data[:name] || node_data['name']
        @tag = node_data[:tag] || node_data['tag']
        @type = node_data[:type] || node_data['type']
        @xpath_query = node_data[:xpath_query] || node_data['xpath_query']
        ObjectSpace.define_finalizer(self, @driver.class.node_handle_disposer(@driver, @element_handle))
      end

      def [](attribute)
        get_attribute(attribute)
      end

      def ==(other)
        @driver.node_equal(self, other)
      end

      def evaluate_ruby(ruby_source = '', &block)
        ruby_source = Isomorfeus::Puppetmaster.block_source_code(&block) if block_given?
        compiled_ruby = compile_ruby_source(ruby_source)
        if compiled_ruby.start_with?('/*')
          start_of_code = compiled_ruby.index('*/') + 3
          compiled_ruby = compiled_ruby[start_of_code..-1]
        end
        javascript = <<~JAVASCRIPT
          (function(){
            if (typeof Opal === "undefined") {
              #{Isomorfeus::Puppetmaster.opal_prelude}
            }
            return #{compiled_ruby}
          })()
        JAVASCRIPT
        evaluate_script(javascript)
      end

      def get_attribute(attribute)
        attribute = attribute.to_s
        if !(attribute.start_with?('aria-') || attribute.start_with?('data-'))
          attribute = attribute.camelize(:lower)
        end
        @driver.node_get_attribute(self, attribute)
      end

      def get_property(property)
        property = property.to_s.camelize(:lower)
        @driver.node_get_property(self, property)
      end

      def has_content?(content, **options)
        visible_text.include?(content)
      end

      def has_css?(selector, **options)
        res = find_all(selector)
        return false unless res
        return false if options.has_key?(:count) && options[:count] != res.size
        return true
      end

      def has_text?(text, **options)
        count = visible_text.scan(/#{text}/).size
        return false if options.has_key?(:count) && options[:count] != count
        count > 0
      end

      def has_xpath?(query, **options)
        res = find_all_xpath(query)
        return false unless res
        return false if options.has_key?(:count) && options[:count] != res.size
        return true
      end

      def html
        get_property(:outerHTML)
      end

      def inner_html
        get_property(:innerHTML)
      end

      def method_missing(name, *args)
        method_name = name.to_s
        if method_name.start_with?('find_by_')
          what = method_name[8..-1]
          return find("[#{what}=\"#{args.first}\"]") if %w[name type value].include?(what)
          return find_xpath("//*[text()=\"#{args.first}\"]") if what == 'content'
        # elsif method_name.start_with?('has_')
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
        Isomorfeus::Puppetmaster::Document.new(@driver, new_documents.first, Isomorfeus::Puppetmaster::Response.new)
      end

      def parents
        find_all_xpath('./ancestor::*').reverse
      end

      def respond_to?(name, include_private = false)
        return true if %i[find_by_content find_by_name find_by_type find_by_value].include?(name)
        super(name, include_private)
      end

      def within(&block)
        instance_exec(&block)
      end

      # assertions
      #       # probably can keep
      #       :assert_all_of_selectors,
      #       :assert_any_of_selectors,
      #       :assert_selector,
      #       :assert_text,
      #       :assert_no_selector,
      #       :assert_none_of_selectors,
      #       :assert_no_text,
      #       :refute_selector

      protected

      def compile_ruby_source(source_code)
        # TODO maybe use compile server
        Opal.compile(source_code, parse_comments: false)
      end
    end
  end
end