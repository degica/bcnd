$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "bcnd"
  s.version = "0.0.1"
  s.files = Dir["lib/**/*", "README.md", "Rakefile"]
  s.require_paths = ["lib"]

  s.add_dependency 'octokit'
  s.add_dependency 'rest-client'
  s.add_dependency 'activesupport'
  s.add_dependency 'rake'
  s.add_development_dependency "rspec"
end
