require './lib/isomorfeus/puppetmaster/version.rb'

Gem::Specification.new do |s|
  s.name         = 'isomorfeus-puppetmaster'
  s.version      = Isomorfeus::PUPPETMASTER_VERSION
  s.author       = 'Jan Biedermann'
  s.email        = 'jan@kursator.de'
  s.homepage     = 'http://isomorfeus.com'
  s.license      = 'MIT'
  s.summary      = 'Acceptance testing for isomorfeus.'
  s.description  = 'Acceptance testing for isomorfeus.'

  s.files          = `git ls-files -- {lib,LICENSE,README.md}`.split("\n")
  s.require_paths  = ['lib']

  s.add_dependency 'activesupport'
  s.add_dependency 'isomorfeus-speednode', '~> 0.2.2'
  s.add_dependency 'method_source'
  s.add_dependency 'opal', '>= 0.11.0'
  s.add_dependency 'opal-browser', '>= 0.2.0'
  s.add_dependency 'parser'
  # s.add_dependency 'uglifier', '~> 4.1.20'
  s.add_dependency 'unparser'
  s.add_development_dependency 'agoo', '~> 2.8.2'
  s.add_development_dependency 'chunky_png'
  s.add_development_dependency 'fastimage'
  s.add_development_dependency 'irb'
  s.add_development_dependency 'launchy', '~> 2.0'
  s.add_development_dependency 'nokogiri', '~> 1.10.1'
  s.add_development_dependency 'os'
  s.add_development_dependency 'pdf-reader', '>= 1.3.3'
  s.add_development_dependency 'puma', '3.12.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.6'
  s.add_development_dependency 'sinatra', '~> 2.0'
end
