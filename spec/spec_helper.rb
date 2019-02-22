$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bcnd'
require 'webmock/rspec'
require 'stub_env'

RSpec.configure do |config|
  config.include StubEnv::Helpers
end
