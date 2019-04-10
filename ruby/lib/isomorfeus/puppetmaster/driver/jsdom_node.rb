module Isomorfeus
  module Puppetmaster
    module Driver
      module JsdomNode
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
          raise ArgumentError, 'Unknown event' unless Isomorfeus::Puppetmaster::Driver::Jsdom::EVENTS.key?(name.to_sym) || event_type
          event_type, opts = *Isomorfeus::Puppetmaster::Driver::Jsdom::EVENTS[name.to_sym] if event_type.nil?
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
          # TODO this wont work yet
          await <<~JAVASCRIPT
            var node_handle = #{node.handle};
            await AllElementHandles[node_handle].executionContext().evaluateHandle((node, arguments) => {
              arguments.unshift(node);
              #{script}
            }, AllElementHandles[node_handle], #{args[1..-1]});
          JAVASCRIPT
        end

        def node_evaluate_script(node, script, *args)
          # TODO this wont work yet
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
          @context.eval "AllElementHandles[#{node.handle}].getAttribute('#{attribute}')"
        end

        def node_get_property(node, property)
          @context.eval "AllElementHandles[#{node.handle}]['#{property}']"
        end

        def node_hover(node)
          @context.exec "AllElementHandles[#{node.handle}].hover()"
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
      end
    end
  end
end
