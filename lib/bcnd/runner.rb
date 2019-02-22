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
      else
        puts "Can't recognize the current stage"
      end
    end

    private

    def deploy_mainline
      image_id = quay.docker_image_id_for_tag(repo: env.quay_repository, tag: env.commit)
      if image_id
        # Skip if docker tag for the commit already exists
        # This typically happens when a CI build is manually restarted
        puts "Found the tagged image #{env.commit}"
      else
        quay.wait_for_automated_build(repo: env.quay_repository, git_sha: env.commit)
        image_id = quay.docker_image_id_for_tag(repo: env.quay_repository, tag: env.branch)
        quay.put_tag(repo: env.quay_repository, image_id: image_id, tag: env.commit)
        puts "attached tag #{env.commit} to image #{image_id}"
      end

      bcn_deploy(env.commit, env.mainline_heritage_token)
    end

    def deploy_stable
      comp = github.compare(env.repository, env.mainline_branch, env.stable_branch)
      tag = comp.merge_base_commit.sha
      image_id = quay.docker_image_id_for_tag(repo: env.quay_repository, tag: tag)
      raise "There is no docker image to be deployed" unless image_id

      bcn_deploy(tag, env.stable_heritage_token)
    end

    def quay
      @quay ||= Bcnd::QuayIo.new(env.quay_token)
    end

    def github
      @github ||= Octokit::Client.new(access_token: env.github_token)
    end

    def bcn_deploy(tag, token)
      system "bcn deploy -e #{env.deploy_environment} --tag #{tag} --heritage-token #{token} 1> /dev/null"
      puts "deploy triggered with tag #{tag} to #{env.deploy_environment} environment"
      if $?.exitstatus != 0
        raise "bcn returned non-zero exitcode #{$?.exitstatus}"
      end
    end
  end
end
