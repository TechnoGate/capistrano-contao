# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capistrano-contao/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Wael M. Nasreddine"]
  gem.email         = ["wael.nasreddine@gmail.com"]
  gem.description   = 'Capistrano receipts for Contao deployment'
  gem.summary       = gem.summary
  gem.homepage      = 'http://technogate.github.com/contao'
  gem.required_ruby_version = Gem::Requirement.new('>= 1.9.2')

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-contao"
  gem.require_paths = ["lib"]
  gem.version       = TechnoGate::Capistrano::Contao::VERSION

  # Runtime dependencies
  gem.add_dependency 'rake'
  gem.add_dependency 'activesupport'

  # Development dependencies
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'fakefs'
end
