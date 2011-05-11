# encoding: utf-8

require File.join(File.dirname(__FILE__), 'lib/ruote/cassandra/version')
  # bundler wants absolute path


Gem::Specification.new do |s|
  s.name = 'ruote-cassandra'
  s.version = Ruote::Cassandra::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'Hartog de Mik' ]
  s.email = [ 'hartog.de.mik@gmail.com' ]
  s.homepage = 'http://simplic.it/'
  s.rubyforge_project = ''
  s.summary = 'Cassandra storage for ruote (a Ruby workflow engine)'
  s.description = %q{
Cassandra storage for ruote (a Ruby workflow engine)
}

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  s.add_runtime_dependency 'cassandra', '0.9.1'
  s.add_runtime_dependency 'ruote', ">= 2.2.0"

  s.add_development_dependency 'rake'

  s.require_path = 'lib'
end
