# frozen_string_literal: true

module PuppetmasterSpec
  shared_examples '#evaluate_script' do
    it 'should evaluate the given script and return whatever it produces' do
      @doc = visit('/with_js')
      expect(@doc.evaluate_script('1+3')).to eq(4)
    end

    it 'should ignore leading and trailing whitespace' do
      @doc = visit('/with_js')
      expect(@doc.evaluate_script('
        1 + 3
      ')).to eq(4)
    end

    it 'should pass arguments to the script', requires: %i[js es_args] do
      @doc = visit('/with_js')
      expect(@doc).to have_css('#change')
      @doc.evaluate_script("document.getElementById('change').textContent = arguments[0]", 'Doodle Funk')
      expect(@doc).to have_css('#change', text: 'Doodle Funk')
    end

    it 'should support passing elements as arguments to the script', requires: %i[js es_args] do
      skip 'not supported'
      @doc = visit('/with_js')
      el = @doc.find('#change')
      @doc.evaluate_script('arguments[0].textContent = arguments[1]', el, 'Doodle Funk')
      expect(@doc).to have_css('#change', text: 'Doodle Funk')
    end

    it 'should support returning elements', requires: %i[js es_args] do
      skip 'todo'
      @doc = visit('/with_js')
      @doc.find('#change') # ensure page has loaded and element is available
      el = @doc.evaluate_script("document.getElementById('change')")
      expect(el).to be_instance_of(Isomorfeus::Puppetmaster::Node)
      expect(el).to eq(@doc.find(:css, '#change'))
    end

    it 'should evaluate ruby in the app context' do
      on_server do
        TEST_CONST = 10 unless defined? TEST_CONST
      end
      app_constants = on_server do
        Module.constants.sort
      end
      val = on_server do
        TEST_CONST
      end
      server_context = on_server do
        self.class.to_s
      end
      loc_val = TEST_CONST if defined?(TEST_CONST)
      local_constants = Module.constants.sort
      expect(app_constants).to include(:Rack, :TestApp)
      expect(val).to eq(10)
      expect(local_constants).not_to include(:TEST_CONST)
      expect(loc_val).to be(nil)
      expect(server_context).to eq('Class')
    end

    context 'without Opal defined' do
      it 'should evaluate ruby as string' do
        @doc = visit('/with_js')
        expect(@doc.evaluate_with_opal('1 + 3')).to eq(4)
      end

      it 'should evaluate ruby as string and be able to use opal-browser' do
        @doc = visit('/with_js')
        expect(@doc.evaluate_with_opal('$document["drag_scroll"].id')).to eq('drag_scroll')
      end

      it 'should evaluate ruby as a block' do
        @doc = visit('/with_js')
        result = @doc.evaluate_with_opal do
          a = 1
          b = 4
          a + b
        end
        expect(result).to eq(5)

        p = proc do
          @doc.evaluate_with_opal do
            a = 2
            b = 4
            a + b
          end
        end
        result = p.call
        expect(result).to eq(6)
      end

      it 'should evaluate ruby as a block and be able to use opal-browser' do
        @doc = visit('/with_js')
        result = @doc.evaluate_with_opal do
          my_id = "drag_scroll"
          $document[my_id].id
        end
        expect(result).to eq('drag_scroll')
      end

      it 'should evaluate ruby isomorphically' do
        @doc = visit('/with_js')
        client_result = @doc.isomorphic_with_opal do
          10 + 5
        end
        expect(client_result).to eq(15)
      end
    end

    context 'with Opal defined' do
      it 'should evaluate ruby as string' do
        @doc = visit('/with_opal')
        expect(@doc.evaluate_ruby('1 + 3')).to eq(4)
      end

      it 'should evaluate ruby as string and be able to use opal-browser' do
        @doc = visit('/with_opal')
        expect(@doc.evaluate_ruby('$document["a_div"].id')).to eq('a_div')
      end

      it 'should evaluate ruby as a block' do
        @doc = visit('/with_opal')
        result = @doc.evaluate_ruby do
          a = 1
          b = 4
          a + b
        end
        expect(result).to eq(5)

        p = proc do
          @doc.evaluate_ruby do
            a = 2
            b = 4
            a + b
          end
        end
        result = p.call
        expect(result).to eq(6)
      end

      it 'should evaluate ruby as a block and be able to use opal-browser' do
        @doc = visit('/with_opal')
        result = @doc.evaluate_ruby do
          my_id = "a_div"
          $document[my_id].id
        end
        expect(result).to eq('a_div')
      end

      it 'should evaluate ruby isomorphically' do
        @doc = visit('/with_opal')
        @doc.isomorphic do
          TEST_OPAL_CONST = 12 unless defined? TEST_OPAL_CONST
        end
        client_result = @doc.evaluate_ruby do
          TEST_OPAL_CONST
        end
        server_result = on_server do
          TEST_OPAL_CONST
        end
        expect(client_result).to eq(12)
        expect(server_result).to eq(12)
      end
    end
  end
end

