require 'rake'
require 'bcnd'

namespace :bcnd do
  desc "test"
  task :test do
    system "bcn deploy -e staging"
  end

  desc "Run deployment"
  task :deploy do
    runner = Bcnd::Runner.new
    runner.deploy
  end
end
