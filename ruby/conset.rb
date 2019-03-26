PUPPETMASTER_ROOT = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(PUPPETMASTER_ROOT, 'lib'))
ENV['NODE_PATH'] = File.join(PUPPETMASTER_ROOT, 'node_modules')

require 'bundler/setup'
require 'rspec'
require 'capybara/spec/spec_helper'
require 'isomorfeus-puppetmaster'

D = Isomorfeus::Puppetmaster.new