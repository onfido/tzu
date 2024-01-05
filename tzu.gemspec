# frozen_string_literal: true

require_relative "lib/tzu/version"

Gem::Specification.new do |s|
  s.name = "tzu"
  s.version = Tzu::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Morgan Bruce", "Blake Turner"]
  s.description = "Tzu is a library for issuing commands in Ruby"
  s.summary = "Standardise and encapsulate your application's actions"
  s.email = "morgan@onfido.com"
  s.homepage = "https://github.com/onfido/tzu"
  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + %w[LICENSE.txt README.md]
  s.require_paths = ["lib"]

  s.add_dependency "activesupport", ">= 4.2", "< 8"
end
