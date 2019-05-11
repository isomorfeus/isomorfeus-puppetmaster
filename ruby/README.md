# isomorfeus-puppetmaster

A framework for acceptance tests or simply running tests in a headless browser. 
Comes with drivers for chromium headless, firefox and jsdom.
Allows for writing javascript tests in pure ruby.

### Community and Support
At the [Isomorfeus Framework Project](http://isomorfeus.com)

## Running on:
- [CircleCI](https://circleci.com): [![CircleCI](https://circleci.com/gh/isomorfeus/isomorfeus-puppetmaster/tree/master.svg?style=svg)](https://circleci.com/gh/isomorfeus/isomorfeus-puppetmaster/tree/master)
- [SemaphoreCI 2.0](https://semaphoreci.com): (not yet available)
- [TravisCI](https://travis-ci.org): [![Build Status](https://travis-ci.org/isomorfeus/isomorfeus-puppetmaster.svg?branch=master)](https://travis-ci.org/isomorfeus/isomorfeus-puppetmaster)
 
## Installation

In Gemfile:
`gem 'isomorfeus-puppetmaster'`, then `bundle install`

Also requires the following npm modules with recommended versions:

- puppeteer 1.13.0 - for the chromium driver
- puppeteer-firefox 0.5.0 - for the firefox driver
- jsdom 14.0.0 - for the jsdom driver
- canvas 2.4.1 - for the jsdom driver

Simply install them in your projects root. Puppetmaster also depends on isomorfeus-speednode, which will be installed automatically.
Speednode will pickup the node modules then from the projects root node_modules directory.

## Configuration

Puppetmaster provides these drivers:
- chromium - a real browser, headless, fast
- chromium_wsl - as above but with options os it can execute within the Windows Linux WSL
- chromium_debug - opens a chromium browser window with devtools enabled, useful for debugging tests
- firefox - real firefox, running headless, not so fast
- firefox_debug - opens a firefox browser window with devtools enabled, useful for debugging tests
- jsdom - provides a dom implementation in javascript, can execute javascript in the document, super fast, headless, has certain limitations,
  especially because its not rendering anything (no element bounding box, etc.)

Selecting a driver, for example jsdom:
```ruby
Isomorfeus::Puppetmaster.driver = :jsdom
```
(chromium is the default driver)


Getting the app ready and running:
1. Assign a rack app
2. Boot the app

For Example:
````ruby
Isomorfeus::Puppetmaster.app = TestApp
Isomorfeus::Puppetmaster.boot_app
````

Include the Puppetmaster DSL in the spec_helper.rb:
```ruby
RSpec.configure do |config|
  config.include Isomorfeus::Puppetmaster::DSL
end
```
Ready to play!

## Terminology

There are Browsers which may have windows or tabs, which translate to targets or pages which may contain documents or frames which consist of elements or nodes.
In Puppetmaster, which is focusing on headless testing, the main "thing" is **just a document**. Its possible to open many documents at once, but what exactly a document is contained in,
a window or tab or browser or target or whatever, is not of interest.
A document consists of nodes. Simply working with just documents and nodes makes testing a lot simpler.
``` 
document
    |____head (is a node)
    |      |
    |      |___more nodes
    |      |___...
    | 
    |____body (is a node)
           |
           |___more nodes
           |___...
```

## Basic usage pattern

1. Find something
2. Interact with it

## Documents
The drivers open a empty default document, to use that and go to the apps root page:
```ruby
doc = visit('/')
```
This provides the document `doc` which can further be used to interact with.
To go to another location, call visit or goto on that doc:
```ruby
doc.visit('/login') # or
doc.goto('/login')
```

To open another document:
```ruby
doc2 = open_new_document('/play')
```

Both open documents can then be independently interacted with:
```ruby
doc.visit('/go')
doc2.goto('/location')
```
### Documents and Ruby

Ruby can be executed within documents by simply providing a block or a string:
```ruby
doc.evaluate_ruby do
  $document['my_id'].class_names
end

# or

doc.evaluate_ruby "$document['my_id'].class_names"
```

The complete API of [opal-browser](https://github.com/opal/opal-browser) is available.

### Documents and Javascript

Javascript can be be evaluated within documents by simply providing a string:
```ruby
doc.evaluate_javascript '1+1' # => 2
```

#### Executing Javascript

TODO

#### DOM changes by Javascript, Timing

TODO
 
## Nodes

### Finding Nodes ...

Nodes can be found by CSS selectors or XPath queries.
Node can be found from the document or or other nodes as root.

#### ... with CSS selectors

Documents and nodes provide methods for finding single nodes or a group of nodes with CSS selectors. Examples:
Find a single node in a document:
```ruby
node1 = doc.find('div') # finds the first div in the document
node2 = doc.find('#super') # find node with id="super"
```
Find a single from another node:
```ruby
node3 = node1.find('div') # find first div within the node
```

Find multiple nodes in a document or from a node:
```ruby
node_array1 = doc.find_all('div') # finds all div's in a document
node_array2 = node2.find_all('div') # find all div's within node2
```

#### ... with XPath queries

Documents and nodes provide methods for finding single nodes or a group of nodes with Xpath queries. Examples:
Find a single node in a document:
```ruby
node1 = doc.find_xpath('//div') # finds the first div in the document
node2 = doc.find_xpath("//div[contains(@id,'super')]") # find div with id="super"
```
Find a single from another node:
```ruby
node3 = node1.find_xpath('//div') # find first div within the node
```

Find multiple nodes in a document or from a node:
```ruby
node_array1 = doc.find_all_xpath('//div') # finds all div's in a document
node_array2 = node2.find_all_xpath('//div') # find all div's within node2
```

### Interacting with nodes

Puppetmaster provides methods for emulating user interactions with nodes or documents.

### Mouse
```ruby
node1.click
```
TODO

### Keyboard
```ruby
node4 = doc.find('input')
node4.type_keys('Message')
```
TODO

### Fingers
TODO


### Tests
To run tests:
- clone repo
- `bundle install`
- `bundle exec rake`
