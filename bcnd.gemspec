$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "bcnd"
  s.version     = "0.0.1"
  s.authors     = ['Kazunori Kajihiro']
  s.summary     = "Deploy your application"
  s.description = "Deploy your application"
  s.homepage    = "https://github.com/degica/bcnd"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "README.md", "Rakefile"]
  s.bindir = 'bin'
  s.executables = ['bcnd']
  s.require_paths = ["lib"]

  s.add_dependency 'octokit'
  s.add_dependency 'rest-client'
  s.add_dependency 'activesupport'
  s.add_dependency 'rake'
  s.add_development_dependency "rspec"
  s.add_development_dependency "webmock"
end
