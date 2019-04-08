# frozen_string_literal: true

module PuppetmasterSpec
  shared_examples '#evaluate_script' do
    it 'should evaluate the given script and return whatever it produces' do
      @doc = visit('/with_js')
      expect(@doc.evaluate_script('1+3')).to eq(4)
    end

    it 'should ignore leading and trailing whitespace' do
      skip 'todo'
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
      skip 'not supported'
      @doc.visit('/with_js')
      @doc.find('#change') # ensure page has loaded and element is available
      el = @oc.evaluate_script("document.getElementById('change')")
      expect(el).to be_instance_of(Capybara::Node::Element)
      expect(el).to eq(@doc.find(:css, '#change'))
    end
  end
end

