# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sass/prof/version'

Gem::Specification.new do |spec|
  spec.name          = "sass-prof"
  spec.version       = Sass::Prof::VERSION
  spec.authors       = ["ezekg"]
  spec.email         = ["ezekg@yahoo.com"]

  spec.summary       = %q{Profiler for Sass libraries.}
  spec.description   = %q{Sass Prof is a code profiler for Sass. For each function, Sass Prof will show the execution time for the function, which file called it and what arguments were given when the function was called.}
  spec.homepage      = "https://github.com/ezekg/sass-prof"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "sass", "~> 3.4"
end
