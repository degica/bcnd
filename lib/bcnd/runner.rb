require 'octokit'

module Bcnd
  class Runner
    attr_accessor :env
    def initialize
      self.env = Bcnd::CI.new
    end

    def deploy
      return if env.pull_request?
      case env.deploy_stage
      when :mainline
        deploy_mainline
      when :stable
        deploy_stable
      end
    end

    private

    def deploy_mainline
      quay.wait_for_automated_build(repo: env.quay_repository, git_sha: env.commit)
      image_id = quay.docker_image_id_for_tag(repo: env.quay_repository, tag: 'latest')
      quay.put_tag(repo: env.quay_repository, image_id: image_id, tag: env.commit)
      bcn_deploy(env.commit)
    end

    def deploy_stable
      comp = github.compare(env.repository, 'master', 'production')
      unless comp.files.empty?
        raise "master and production are not same"
      end

      tag = comp.base_commit.sha
      image_id = quay.docker_image_id_for_tag(repo: env.quay_repository, tag: tag)
      unless image_id
        raise "There is no docker image to be deployed"
        return
      end

      bcn_deploy(tag)
    end

    def quay
      @quay ||= Bcnd::QuayIo.new(env.quay_token)
    end

    def github
      @github ||= Octokit::Client.new(access_token: env.github_token)
    end

    def bcn_deploy(tag)
      system "bcn deploy -e #{env.deploy_environment} --tag #{tag} --heritage-token #{env.heritage_token}"
    end
  end
end
