$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "bcnd"
  s.version     = "0.2.0"
  s.authors     = ['Kazunori Kajihiro']
  s.email       = ["kkajihiro@degica.com"]

  s.summary     = "Degica's opinionated deployment tool"
  s.description = "Degica's opinionated deployment tool."
  s.homepage    = "https://github.com/degica/bcnd"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "README.md", "Rakefile"]
  s.bindir = 'bin'
  s.executables = ['bcnd']
  s.require_paths = ["lib"]

  s.add_dependency 'octokit', '~> 4.2'
  s.add_dependency 'rest-client', '~> 1.8'
  s.add_development_dependency "rspec", '~> 3.2'
  s.add_development_dependency "webmock", '~> 1.22'
end
