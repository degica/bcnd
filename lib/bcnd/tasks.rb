require 'rake'
require 'octokit'
require 'bcnd'

namespace :bcnd do
  desc "test"
  task :test do
    system "bcn deploy -e staging"
  end
  task :deploy do
    env = Bcnd::CI.new
    p env
    exit if env.pull_request?
    case env.branch
    when env.staging_branch
      deploy_staging(env)
    when env.production_branch
      deploy_production(env)
    end
  end

  private

  def deploy_staging(env)
    quay.wait_for_automated_build(repo: env.repository, git_sha: env.commit)
    image_id = quay.docker_image_id_for_tag(repo: env.repository, tag: 'latest')
    quay.put_tag(repo: env.repository, image_id: image_id, tag: env.commit)
    bcn_deploy env
  end

  def deploy_production(env)
    comp = github.compare(env.repository, 'master', 'production')
    unless comp.files.empty?
      puts "master and production are not same"
      exit 1
    end

    image_id = quay.docker_image_id_for_tag(repo: env.repository, tag: env.commit)
    unless image_id
      puts "There is no docker image to be deployed"
      exit 1
    end

    bcn_deploy env
  end

  def quay
    @quay ||= Bcnd::QuayIo.new(env.quay_token)
  end

  def github
    @github ||= Octokit::Client.new(access_token: env.github_token)
  end

  def bcn_deploy(env)
    system "bcn deploy -e staging --tag #{env.commit} --heritage-token #{env.heritage_token}"
  end
end
