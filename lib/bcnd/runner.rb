require 'octokit'

module Bcnd
  class Runner
    attr_accessor :env
    def initialize
      self.env = Bcnd::CI.new
    end

    def deploy
      exit if env.pull_request?
      case env.branch
      when env.staging_branch
        deploy_staging
      when env.production_branch
        deploy_production
      end
    end

    private

    def deploy_staging
      quay.wait_for_automated_build(repo: env.repository, git_sha: env.commit)
      image_id = quay.docker_image_id_for_tag(repo: env.repository, tag: 'latest')
      quay.put_tag(repo: env.repository, image_id: image_id, tag: env.commit)
      bcn_deploy env
    end

    def deploy_production
      comp = github.compare(env.repository, 'master', 'production')
      unless comp.files.empty?
        puts "master and production are not same"
        exit 1
      end

      image_id = quay.docker_image_id_for_tag(repo: env.repository, tag: comp.base_commit.sha)
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
      system "bcn deploy -e #{env.deploy_environment} --tag #{env.commit} --heritage-token #{env.heritage_token}"
    end
  end
end
