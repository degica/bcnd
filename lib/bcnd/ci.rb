module Bcnd
  class CI
    attr_accessor :repository,
      :commit,
      :branch,
      :quay_repository,
      :quay_token,
      :github_token,
      :heritage_token

    def initialize
      load_environment
      self.quay_token = ENV['QUAY_TOKEN']
      self.github_token = ENV['GITHUB_TOKEN']
      self.heritage_token = ENV['HERITAGE_TOKEN']
      self.quay_repository = ENV['QUAY_REPOSITORY'] || self.repository
    end

    def load_environment
      case ci_service
      when :travis
        self.repository = ENV['TRAVIS_REPO_SLUG']
        self.commit = ENV['TRAVIS_COMMIT']
        self.branch = ENV['TRAVIS_BRANCH']
      end
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

    def staging_branch
      "master"
    end

    def production_branch
      "production"
    end
  end
end
