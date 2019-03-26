# frozen_string_literal: true

module PuppetmasterSpec
  shared_examples '#find enhanced' do
    before do
      @doc = visit('/with_html')
    end

    it 'should wait for asynchronous load', requires: [:js] do
      @doc.visit('/with_js')
      @doc.find_by_content('Click me').click
      expect(@doc.wait_for('a#has-been-clicked').visible_text).to include('Has been clicked')
    end
  end

  shared_examples '#find' do
    before do
      @doc = visit('/with_html')
    end

    it 'should find the first element using the given locator' do
      expect(@doc.find_xpath('//h1').visible_text).to eq('This is a test')
      expect(@doc.find_xpath("//input[@id='test_field']").value).to eq('monkey')
    end

    it 'should find the first element using the given locator and options' do
      skip 'currently not supported'
      expect(@doc.find_xpath('//a', text: 'Redirect')[:id]).to eq('red')
      expect(@doc.find('a', text: 'A link came first')[:title]).to eq('twas a fine link')
    end

    it 'should raise an error if there are multiple matches' do
      skip 'find_xpath locates the first element only'
      expect { @doc.find_xpath('//a') }.to raise_error()
    end

    context 'with :text option' do
      it "casts text's argument to string" do
        skip 'not applicable'
        expect(@doc.find('.number', text: 42)).to have_content('42')
      end
    end

    context 'with :wait option', requires: [:js] do
      it 'should not wait for asynchronous load when `false` given' do
        skip 'no applicable'
        @doc.visit('/with_js')
        @doc.click_link('Click me')
        expect do
          @doc.find(:css, 'a#has-been-clicked', wait: false)
        end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it 'should not find element if it appears after given wait duration' do
        skip 'no applicable'
        @doc.visit('/with_js')
        @doc.click_link('Slowly')
        expect do
          @doc.find(:css, 'a#slow-clicked', wait: 0.2)
        end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it 'should find element if it appears before given wait duration' do
        skip 'no applicable'
        @doc.visit('/with_js')
        @doc.click_link('Click me')
        expect(@doc.find(:css, 'a#has-been-clicked', wait: 3.0).text).to include('Has been clicked')
      end
    end

    context 'with frozen time', requires: [:js] do
      if defined?(Process::CLOCK_MONOTONIC)
        it 'will time out even if time is frozen' do
          @doc.visit('/with_js')
          now = Time.now
          allow(Time).to receive(:now).and_return(now)
          expect { @doc.find_xpath('//isnotthere') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
        end
      else
        it 'raises an error suggesting that Capybara is stuck in time' do
          @doc.visit('/with_js')
          now = Time.now
          allow(Time).to receive(:now).and_return(now)
          expect { @doc.find('//isnotthere') }.to raise_error(Capybara::FrozenInTime)
        end
      end
    end

    context 'with css selectors' do
      it 'should find the first element using the given locator' do
        expect(@doc.find('h1').visible_text).to eq('This is a test')
        expect(@doc.find("input[id='test_field']").value).to eq('monkey')
      end

      it 'should support pseudo selectors' do
        expect(@doc.find('input:disabled').value).to eq('This is disabled')
      end

      it 'should support escaping characters' do
        expect(@doc.find('#\31 escape\.me').visible_text).to eq('needs escaping')
        expect(@doc.find('.\32 escape').visible_text).to eq('needs escaping')
      end

      it 'should not warn about locator' do
        skip 'not applicable'
        expect { @doc.find('#not_on_page') }.to raise_error Isomorfeus::Puppetmaster::ElementNotFound do |e|
          expect(e.message).not_to match(/you may be passing a CSS selector or XPath expression/)
        end
      end
    end

    context 'with xpath selectors' do
      it 'should find the first element using the given locator' do
        expect(@doc.find_xpath('//h1').visible_text).to eq('This is a test')
        expect(@doc.find_xpath("//input[@id='test_field']").value).to eq('monkey')
      end

      it 'should warn if passed a non-valid locator type' do
        skip 'not applicable'
        expect_any_instance_of(Kernel).to receive(:warn).with(/must respond to to_xpath or be an instance of String/)
        expect { @doc.find_xpath(123) }.to raise_error # rubocop:disable RSpec/UnspecifiedException
      end
    end

    context 'with custom selector' do
      it 'should use the custom selector' do
        skip 'not applicable'
        Capybara.add_selector(:beatle) do
          xpath { |name| ".//*[@id='#{name}']" }
        end
        expect(@doc.find(:beatle, 'john').text).to eq('John')
        expect(@doc.find(:beatle, 'paul').text).to eq('Paul')
      end
    end

    context 'with custom selector with custom `match` block' do
      it 'should use the custom selector when locator matches the block' do
        skip 'not applicable'
        Capybara.add_selector(:beatle) do
          xpath { |num| ".//*[contains(@class, 'beatle')][#{num}]" }
          match { |value| value.is_a?(Integer) }
        end
        expect(@doc.find(:beatle, '2').text).to eq('Paul')
        expect(@doc.find(1).text).to eq('John')
        expect(@doc.find(2).text).to eq('Paul')
        expect(@doc.find('//h1').text).to eq('This is a test')
      end
    end

    context 'with custom selector with custom filter' do
      before do
        # Capybara.add_selector(:beatle) do
        #   xpath { |name| ".//li[contains(@class, 'beatle')][contains(text(), '#{name}')]" }
        #   node_filter(:type) { |node, type| node[:class].split(/\s+/).include?(type) }
        #   node_filter(:fail) { |_node, _val| raise Isomorfeus::Puppetmaster::ElementNotFound, 'fail' }
        # end
      end

      it 'should find elements that match the filter' do
        skip 'not applicable'
        expect(@doc.find(:beatle, 'Paul', type: 'drummer').text).to eq('Paul')
        expect(@doc.find(:beatle, 'Ringo', type: 'drummer').text).to eq('Ringo')
      end

      it 'ignores filter when it is not given' do
        skip 'not applicable'
        expect(@doc.find(:beatle, 'Paul').text).to eq('Paul')
        expect(@doc.find(:beatle, 'John').text).to eq('John')
      end

      it "should not find elements that don't match the filter" do
        skip 'not applicable'
        expect { @doc.find(:beatle, 'John', type: 'drummer') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
        expect { @doc.find(:beatle, 'George', type: 'drummer') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it 'should not raise an ElementNotFound error from in a filter' do
        skip 'not applicable'
        expect { @doc.find(:beatle, 'John', fail: 'something') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound, /beatle "John"/)
      end
    end

    context 'with custom selector with custom filter and default' do
      before do
        # Capybara.add_selector(:beatle) do
        #   xpath { |name| ".//li[contains(@class, 'beatle')][contains(text(), '#{name}')]" }
        #   node_filter(:type, default: 'drummer') { |node, type| node[:class].split(/\s+/).include?(type) }
        # end
      end

      it 'should find elements that match the filter' do
        skip 'not applicable'
        expect(@doc.find(:beatle, 'Paul', type: 'drummer').text).to eq('Paul')
        expect(@doc.find(:beatle, 'Ringo', type: 'drummer').text).to eq('Ringo')
      end

      it 'should use default value when filter is not given' do
        skip 'not applicable'
        expect(@doc.find(:beatle, 'Paul').text).to eq('Paul')
        expect { @doc.find(:beatle, 'John') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it "should not find elements that don't match the filter" do
        skip 'not applicable'
        expect { @doc.find(:beatle, 'John', type: 'drummer') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
        expect { @doc.find(:beatle, 'George', type: 'drummer') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end
    end

    context 'with alternate filter set' do
      before do
        # Capybara::Selector::FilterSet.add(:value) do
        #   node_filter(:with) { |node, with| node.value == with.to_s }
        # end
        #
        # Capybara.add_selector(:id_with_field_filters) do
        #   xpath { |id| XPath.descendant[XPath.attr(:id) == id.to_s] }
        #   filter_set(:field)
        # end
      end

      it 'should allow use of filters from custom filter set' do
        skip 'not applicable'
        expect(@doc.find(:id, 'test_field', filter_set: :value, with: 'monkey').value).to eq('monkey')
        expect { @doc.find(:id, 'test_field', filter_set: :value, with: 'not_monkey') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it 'should allow use of filter set from a different selector' do
        skip 'not applicable'
        expect(@doc.find(:id, 'test_field', filter_set: :field, with: 'monkey').value).to eq('monkey')
        expect { @doc.find(:id, 'test_field', filter_set: :field, with: 'not_monkey') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it 'should allow importing of filter set into selector' do
        skip 'not applicable'
        expect(@doc.find(:id_with_field_filters, 'test_field', with: 'monkey').value).to eq('monkey')
        expect { @doc.find(:id_with_field_filters, 'test_field', with: 'not_monkey') }.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end
    end

    context 'with css as default selector' do
      # before { Capybara.default_selector = :css }

      # after { Capybara.default_selector = :xpath }

      it 'should find the first element using the given locator' do
        skip 'not applicable'
        expect(@doc.find('h1').text).to eq('This is a test')
        expect(@doc.find("input[id='test_field']").value).to eq('monkey')
      end
    end

    it 'should raise ElementNotFound with a useful default message if nothing was found' do
      expect do
        @doc.find_xpath('//div[@id="nosuchthing"]').to be_nil
      end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound, 'Unable to find "//div[@id="nosuchthing"]"')
    end

    it 'should accept an XPath instance' do
      skip 'not applicable'
      @doc.visit('/form')
      @xpath = Capybara::Selector[:fillable_field].call('First Name')
      expect(@xpath).to be_a(::XPath::Union)
      expect(@doc.find(@xpath).value).to eq('John')
    end

    context 'with :exact option' do
      it 'matches exactly when true' do
        skip 'not applicable'
        expect(@doc.find(:xpath, XPath.descendant(:input)[XPath.attr(:id).is('test_field')], exact: true).value).to eq('monkey')
        expect do
          @doc.find(:xpath, XPath.descendant(:input)[XPath.attr(:id).is('est_fiel')], exact: true)
        end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
      end

      it 'matches loosely when false' do
        skip 'not applicable'
        expect(@doc.find(:xpath, XPath.descendant(:input)[XPath.attr(:id).is('test_field')], exact: false).value).to eq('monkey')
        expect(@doc.find(:xpath, XPath.descendant(:input)[XPath.attr(:id).is('est_fiel')], exact: false).value).to eq('monkey')
      end

      it 'defaults to `Capybara.exact`' do
        skip 'not applicable'
        Capybara.exact = true
        expect do
          @doc.find(:xpath, XPath.descendant(:input)[XPath.attr(:id).is('est_fiel')])
        end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
        Capybara.exact = false
        @doc.find(:xpath, XPath.descendant(:input)[XPath.attr(:id).is('est_fiel')])
      end

      it 'warns when the option has no effect' do
        skip 'not applicable'
        expect_any_instance_of(Kernel).to receive(:warn)
          .with('The :exact option only has an effect on queries using the XPath#is method. Using it with the query "#test_field" has no effect.')
        @doc.find(:css, '#test_field', exact: true)
      end
    end

    context 'with :match option' do
      context 'when set to `one`' do
        it 'raises an error when multiple matches exist' do
          skip 'not applicable'
          expect do
            @doc.find(:css, '.multiple', match: :one)
          end.to raise_error(Capybara::Ambiguous)
        end
        it 'raises an error even if there the match is exact and the others are inexact' do
          skip 'not applicable'
          expect do
            @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular')], exact: false, match: :one)
          end.to raise_error(Capybara::Ambiguous)
        end
        it 'returns the element if there is only one' do
          skip 'not applicable'
          expect(@doc.find(:css, '.singular', match: :one).text).to eq('singular')
        end
        it 'raises an error if there is no match' do
          skip 'not applicable'
          expect do
            @doc.find(:css, '.does-not-exist', match: :one)
          end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
        end
      end

      context 'when set to `first`' do
        it 'returns the first matched element' do
          skip 'not applicable'
          expect(@doc.find(:css, '.multiple', match: :first).text).to eq('multiple one')
        end
        it 'raises an error if there is no match' do
          skip 'not applicable'
          expect do
            @doc.find(:css, '.does-not-exist', match: :first)
          end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
        end
      end

      context 'when set to `smart`' do
        context 'and `exact` set to `false`' do
          it 'raises an error when there are multiple exact matches' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('multiple')], match: :smart, exact: false)
            end.to raise_error(Capybara::Ambiguous)
          end
          it 'finds a single exact match when there also are inexact matches' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular')], match: :smart, exact: false)
            expect(result.text).to eq('almost singular')
          end
          it 'raises an error when there are multiple inexact matches' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singul')], match: :smart, exact: false)
            end.to raise_error(Capybara::Ambiguous)
          end
          it 'finds a single inexact match' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular but')], match: :smart, exact: false)
            expect(result.text).to eq('almost singular but not quite')
          end
          it 'raises an error if there is no match' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('does-not-exist')], match: :smart, exact: false)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
        end

        context 'with `exact` set to `true`' do
          it 'raises an error when there are multiple exact matches' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('multiple')], match: :smart, exact: true)
            end.to raise_error(Capybara::Ambiguous)
          end
          it 'finds a single exact match when there also are inexact matches' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular')], match: :smart, exact: true)
            expect(result.text).to eq('almost singular')
          end
          it 'raises an error when there are multiple inexact matches' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singul')], match: :smart, exact: true)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
          it 'raises an error when there is a single inexact matches' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular but')], match: :smart, exact: true)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
          it 'raises an error if there is no match' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('does-not-exist')], match: :smart, exact: true)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
        end
      end

      context 'when set to `prefer_exact`' do
        context 'and `exact` set to `false`' do
          it 'picks the first one when there are multiple exact matches' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('multiple')], match: :prefer_exact, exact: false)
            expect(result.text).to eq('multiple one')
          end
          it 'finds a single exact match when there also are inexact matches' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular')], match: :prefer_exact, exact: false)
            expect(result.text).to eq('almost singular')
          end
          it 'picks the first one when there are multiple inexact matches' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singul')], match: :prefer_exact, exact: false)
            expect(result.text).to eq('almost singular but not quite')
          end
          it 'finds a single inexact match' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular but')], match: :prefer_exact, exact: false)
            expect(result.text).to eq('almost singular but not quite')
          end
          it 'raises an error if there is no match' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('does-not-exist')], match: :prefer_exact, exact: false)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
        end

        context 'with `exact` set to `true`' do
          it 'picks the first one when there are multiple exact matches' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('multiple')], match: :prefer_exact, exact: true)
            expect(result.text).to eq('multiple one')
          end
          it 'finds a single exact match when there also are inexact matches' do
            skip 'not applicable'
            result = @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular')], match: :prefer_exact, exact: true)
            expect(result.text).to eq('almost singular')
          end
          it 'raises an error if there are multiple inexact matches' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singul')], match: :prefer_exact, exact: true)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
          it 'raises an error if there is a single inexact match' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('almost_singular but')], match: :prefer_exact, exact: true)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
          it 'raises an error if there is no match' do
            skip 'not applicable'
            expect do
              @doc.find(:xpath, XPath.descendant[XPath.attr(:class).is('does-not-exist')], match: :prefer_exact, exact: true)
            end.to raise_error(Isomorfeus::Puppetmaster::ElementNotFound)
          end
        end
      end

      it 'defaults to `Capybara.match`' do
        skip 'not applicable'
        Capybara.match = :one
        expect do
          @doc.find(:css, '.multiple')
        end.to raise_error(Capybara::Ambiguous)
        Capybara.match = :first
        expect(@doc.find(:css, '.multiple').text).to eq('multiple one')
      end

      it 'raises an error when unknown option given' do
        skip 'not applicable'
        expect do
          @doc.find(:css, '.singular', match: :schmoo)
        end.to raise_error(ArgumentError)
      end
    end

    it 'supports a custom filter block' do
      skip 'not applicable'
      expect(@doc.find('input', &:disabled?)[:name]).to eq('disabled_text')
    end

    context 'within a scope' do
      before do
        @doc.visit('/with_scope')
      end

      it 'should find the an element using the given locator' do
        expect(@doc.find_xpath("//div[@id='for_bar']").within { find_xpath('.//li[1]').visible_text }).to match(/With Simple HTML/)
      end

      it 'should support pseudo selectors' do
        expect(@doc.find_xpath("//div[@id='for_bar']").within { find('input:disabled').value}).to eq('James')
      end
    end

    it 'should raise if selector type is unknown' do
      skip 'not applicable'
      expect do
        @doc.find(:unknown, '//h1')
      end.to raise_error(ArgumentError)
    end

    context 'with Capybara.test_id' do
      it 'should not match on it when nil' do
        skip 'not applicable'
        Capybara.test_id = nil
        expect(@doc).not_to have_field('test_id')
      end

      it 'should work with the attribute set to `data-test-id` attribute' do
        skip 'not applicable'
        Capybara.test_id = 'data-test-id'
        expect(@doc.find(:field, 'test_id')[:id]).to eq 'test_field'
      end

      it 'should use a different attribute if set' do
        skip 'not applicable'
        Capybara.test_id = 'data-other-test-id'
        expect(@doc.find(:field, 'test_id')[:id]).to eq 'normal'
      end
    end
  end
end

