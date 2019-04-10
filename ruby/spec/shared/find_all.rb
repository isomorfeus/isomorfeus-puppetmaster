# frozen_string_literal: true

module PuppetmasterSpec
  shared_examples '#find_all' do
    before do
      @doc = visit('/with_html')
    end

    it 'should find all elements using the given locator' do
      expect(@doc.find_all_xpath('//p').size).to eq(3)
      expect(@doc.find_all_xpath('//h1').first.visible_text).to eq('This is a test')
      expect(@doc.find_all_xpath("//input[@id='test_field']").first.value).to eq('monkey')
    end

    it 'should return an empty array when nothing was found' do
      expect(@doc.find_all_xpath('//div[@id="nosuchthing"]')).to be_empty
    end

    it 'should not wait if not waiting', requires: [:js] do
      @doc.visit('/with_js')
      @doc.find_by_content('Click me').click
      expect(@doc.find_all('a#has-been-clicked')).to be_empty
    end

    it 'should accept an XPath instance', :exact_false do
      skip 'todo'
      @doc.visit('/form')
      @xpath = Capybara::Selector[:fillable_field].call('Name')
      expect(@xpath).to be_a(::XPath::Union)
      @result = @doc.find_all_xpath(@xpath).map(&:value)
      expect(@result).to include('Smith', 'John', 'John Smith')
    end

    it 'should raise an error when given invalid options' do
      expect { @doc.find_all_xpath('//p', schmoo: 'foo') }.to raise_error(ArgumentError)
    end

    context 'with css selectors' do
      it 'should find all elements using the given selector' do
        expect(@doc.find_all('h1').first.visible_text).to eq('This is a test')
        expect(@doc.find_all("input[id='test_field']").first.value).to eq('monkey')
      end

      it 'should find all elements when given a list of selectors' do
        expect(@doc.find_all('h1, p').size).to eq(4)
      end
    end

    context 'with xpath selectors' do
      it 'should find the first element using the given locator' do
        expect(@doc.find_all_xpath('//h1').first.visible_text).to eq('This is a test')
        expect(@doc.find_all_xpath("//input[@id='test_field']").first.value).to eq('monkey')
      end

      it 'should use alternated regex for :id' do
        skip 'todo'
        expect(@doc.find_all_xpath('.//h2', id: /h2/).unfiltered_size).to eq 3
        expect(@doc.find_all_xpath('.//h2', id: /h2(one|two)/).unfiltered_size).to eq 2
      end
    end

    context 'with css as default selector' do
      it 'should find the first element using the given locator' do
        expect(@doc.find_all('h1').first.visible_text).to eq('This is a test')
        expect(@doc.find_all("input[id='test_field']").first.value).to eq('monkey')
      end
    end

    context 'with visible filter' do
      it 'should only find visible nodes when true' do
        skip 'todo'
        expect(@doc.find_all('a.simple', visible: true).size).to eq(1)
      end

      it 'should find nodes regardless of whether they are invisible when false' do
        skip 'todo'
        expect(@doc.find_all('a.simple', visible: false).size).to eq(2)
      end

      it 'should default to ignore hidden elements' do
        skip 'todo'
        expect(@doc.find_all('a.simple').size).to eq(1)
        expect(@doc.find_all('a.simple').size).to eq(2)
      end
    end

    context 'within a scope' do
      before do
        @doc.visit('/with_scope')
      end

      it 'should find any element using the given locator' do
        res = @doc.find_xpath("//div[@id='for_bar']").within do
          find_all_xpath('.//li').size
        end
        expect(res).to eq(2)
      end
    end

  end
end
