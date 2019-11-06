module Isomorfeus
  module Puppetmaster
    module Driver
      module PuppeteerNode
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
            var navigation_watcher = AllPageHandles[#{node.document.handle}].waitForNavigation();
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
          raise ArgumentError, 'Unknown event' unless Isomorfeus::Puppetmaster::Driver::Puppeteer::EVENTS.key?(name.to_sym) || event_type
          event_type, opts = *Isomorfeus::Puppetmaster::Driver::Puppeteer::EVENTS[name.to_sym] if event_type.nil?
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
            var navigation_watcher = AllPageHandles[#{node.document.handle}].waitForNavigation();
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
            handle = await AllElementHandles[node_handle].executionContext().evaluateHandle((node, arguments) => {
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
                var name = node.nodeName;
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [name, tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              LastResult = {handle: node_handle, name: tt[0], tag: tt[1], type: tt[2], content_editable: tt[3]};
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
                  var name = node.nodeName;
                  var tag = node.tagName.toLowerCase();
                  var type = null;
                  if (tag === 'input') { type = node.getAttribute('type'); }
                  return [name, tag, type, node.isContentEditable];
                }, AllElementHandles[node_handle]);
                node_data_array.push({handle: node_handle, name: tt[0], tag: tt[1], type: tt[2], content_editable: tt[3]});
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
                  var name = node.nodeName;
                  var tag = node.tagName.toLowerCase();
                  var type = null;
                  if (tag === 'input') { type = node.getAttribute('type'); }
                  return [name, tag, type, node.isContentEditable];
                }, AllElementHandles[node_handle]);
                node_data_array.push({handle: node_handle, name: tt[0], tag: tt[1], type: tt[2], content_editable: tt[3]});
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
                var name = node.nodeName;
                var tag = node.tagName.toLowerCase();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [name, tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              LastResult = {handle: node_handle, name: tt[0], tag: tt[1], type: tt[2], content_editable: tt[3]};
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
          await <<~JAVASCRIPT
            LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node, attribute){
              return node.getAttribute(attribute);
            }, AllElementHandles[#{node.handle}], '#{attribute}');
          JAVASCRIPT
        end

        def node_get_property(node, property)
          await <<~JAVASCRIPT
            LastResult = await AllElementHandles[#{node.handle}].executionContext().evaluate(function(node, property){
              return node[property];
            }, AllElementHandles[#{node.handle}], '#{property}');
          JAVASCRIPT
        end

        def node_hover(node)
          await "await AllElementHandles[#{node.handle}].hover(); }"
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
            var navigation_watcher = AllPageHandles[#{node.document.handle}].waitForNavigation();
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
              return = window.getComputedStyle(node);
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
                var name = node.nodeName;
                var tag = node.tagName.toLower();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [name, tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              var tt = await handle.jsonValue();
              LastResult = {handle: node_handle, name: tt[0], tag: tt[1], type: tt[2], content_editable: tt[3]};
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
                var name = node.nodeName;
                var tag = node.tagName.toLower();
                var type = null;
                if (tag === 'input') { type = node.getAttribute('type'); }
                return [name, tag, type, node.isContentEditable];
              }, AllElementHandles[node_handle]);
              var tt = await handle.jsonValue();
              LastResult = {handle: node_handle, name: tt[0], tag: tt[1], type: tt[2], content_editable: tt[3]};
            }
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
