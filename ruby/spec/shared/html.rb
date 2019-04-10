# frozen_string_literal: true

# Note: This file uses `sleep` to sync up parts of the tests. This is only implemented like this
# because of the methods being tested. In tests using Capybara this type of behavior should be implemented
# using Capybara provided assertions with builtin waiting behavior.
module PuppetmasterSpec
  shared_examples 'html' do
    context '#html' do
      it 'should return the unmodified page source' do
        @doc = visit('/')
        expect(@doc.html).to include('Hello world!')
      end
    end

    context '#body.visible_text' do
      it 'should return the unmodified page body' do
        @doc = visit('/')
        expect(@doc.body.visible_text).to include('Hello world!')
      end
    end
  end

  shared_examples 'html enhanced' do
    context '#html' do
      it 'should return the current state of the page', requires: [:js] do
        @doc = visit('/with_js')
        expect(@doc.html).to include('I changed it')
        expect(@doc.html).not_to include('This is text')
      end
    end

    context '#body.visible_text' do
      it 'should return the current state of the page', requires: [:js] do
        @doc = visit('/with_js')
        expect(@doc.body.visible_text).to include('I changed it')
        expect(@doc.body.visible_text).not_to include('This is text')
      end
    end
  end
end
