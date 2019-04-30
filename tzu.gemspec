$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = 'tzu'
  s.version = '0.1.2.0'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Morgan Bruce', 'Blake Turner']
  s.description = 'Tzu is a library for issuing commands in Ruby'
  s.summary = "Standardise and encapsulate your application's actions"
  s.email = 'morgan@onfido.com'
  s.homepage = 'https://github.com/onfido/tzu'
  s.license = 'MIT'

  s.files         = Dir.glob("{bin,lib}/**/*") + %w(LICENSE.txt README.md)
  s.test_files    = Dir.glob("{spec}/**/*")
  s.require_paths = ['lib']

  s.add_dependency 'json', '~> 1.8.5'

  s.add_development_dependency 'bundler', '>= 1.0.0'
  s.add_development_dependency 'activerecord', '>= 4.2.7.1'
  s.add_development_dependency 'activesupport', '>= 4.2.7.1'
  s.add_development_dependency 'rspec', '>= 2.4.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'virtus'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler-audit'
end
