# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tiki/torch/version'

Gem::Specification.new do |spec|
  spec.name        = 'tiki_torch'
  spec.version     = Tiki::Torch::VERSION
  spec.authors     = ['Adrian Madrid']
  spec.email       = ['aemadrid@gmail.com']
  spec.description = %q{Inter-service communication library for Ruby}
  spec.summary     = %q{Tiki Torch is a Ruby asynchronous communication library through NSQ.}
  spec.homepage    = ''
  spec.license     = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'nsq-ruby'
  spec.add_dependency 'thread_safe'
  spec.add_dependency 'concurrent-ruby'
  spec.add_dependency 'multi_json'
  spec.add_dependency 'pry'
  spec.add_dependency 'colorize'
  spec.add_dependency 'lifeguard'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rake'
end
