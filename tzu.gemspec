$:.push File.expand_path('../lib', __FILE__)
require 'orm_adapter/version'

Gem::Specification.new do |s|
  s.name = 'tzu'
  s.version = '0.0.2.0'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Morgan Bruce', 'Blake Turner']
  s.description = 'Encapsulate your database queries with dynamically generated classes'
  s.summary = 'Get is a library designed to encapsulate Rails database queries and prevent query pollution in the view layer.'
  s.email = 'morgan@onfido.com'
  s.homepage = 'https://github.com/onfido/tzu'
  s.license = 'MIT'

  s.files         = Dir.glob("{bin,lib}/**/*") + %w(LICENSE.txt README.md)
  s.test_files    = Dir.glob("{spec}/**/*")
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '>= 1.0.0'
  s.add_development_dependency 'activerecord', '>= 3.2.15'
  s.add_development_dependency 'activesupport', '>= 3.2.15'
  s.add_development_dependency 'rspec', '>= 2.4.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'byebug'
end
