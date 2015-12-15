require 'yaml'
module Bcnd
  class CI
    DEFAULT_CONFIG = {
      "mainline_branch" => "master",
      "mainline_environment" => "staging",
      "stable_branch" => "production",
      "stable_environment" => "production"
    }

    attr_accessor :repository,
      :commit,
      :branch,
      :quay_repository,
      :quay_token,
      :github_token,
      :heritage_token,
      :stage_config

    def initialize
      load_ci_environment
      load_stage_config
      self.quay_token = ENV['QUAY_TOKEN']
      self.github_token = ENV['GITHUB_TOKEN']
      self.heritage_token = ENV['HERITAGE_TOKEN']
      self.quay_repository = ENV['QUAY_REPOSITORY'] || self.repository
    end

    def pull_request?
      case ci_service
      when :travis
        ENV['TRAVIS_PULL_REQUEST'] != 'false'
      end
    end

    def ci_service
      if ENV['TRAVIS']
        :travis
      else
        :unknown
      end
    end

    def mainline_branch
      stage_config[:mainline][:branch]
    end

    def stable_branch
      stage_config[:stable][:branch]
    end

    def deploy_stage
      {
        mainline_branch => :mainline,
        stable_branch => :stable
      }[self.branch]
    end

    def deploy_environment
      stage_config[deploy_stage][:environment]
    end

    private

    def load_ci_environment
      case ci_service
      when :travis
        self.repository = ENV['TRAVIS_REPO_SLUG']
        self.commit     = ENV['TRAVIS_COMMIT']
        self.branch     = ENV['TRAVIS_BRANCH']
      end
    end

    def load_stage_config
      config = DEFAULT_CONFIG.merge(load_config_file)
      self.stage_config = {
        mainline: {
          branch: config["mainline_branch"],
          environment: config["mainline_environment"]
        },
        stable: {
          branch: config["stable_branch"],
          environment: config["stable_environment"]
        }
      }
    end

    def load_config_file
      file = File.read('barcelona.yml')
      YAML.load(file)["bcnd"] || {}
    rescue Errno::ENOENT => e
      {}
    end
  end
end
