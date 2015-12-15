require 'rest-client'
require 'json'

module Bcnd
  class QuayIo
    class Connection
      BASE_URL = 'https://quay.io/api/v1'
      attr_accessor :token

      def initialize(token)
        @token = token
      end

      def request(method: :get, path:, body: {}, query_params: {})
        response = RestClient::Request.execute(
          method: method,
          url: "#{BASE_URL}#{path}",
          payload: body.empty? ? nil : body.to_json,
          headers: {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json",
            params: query_params
          }
        )
        JSON.load(response.to_s)
      end

      def get(path:, body: {}, query_params: {})
        request(method: :get, path: path, body: body, query_params: query_params)
      end

      def put(path:, body: {}, query_params: {})
        request(method: :put, path: path, body: body, query_params: query_params)
      end

      def post(path:, body: {}, query_params: {})
        request(method: :post, path: path, body: body, query_params: query_params)
      end

      def delete(path:, body: {}, query_params: {})
        request(method: :delete, path: path, body: body, query_params: query_params)
      end
    end

    attr_accessor :conn

    def initialize(token)
      @conn = Connection.new(token)
    end

    def automated_builds_for(repo:, git_sha:)
      builds = conn.get(path: "/repository/#{repo}/build/")["builds"]
      builds.select do |b|
        b["trigger_metadata"]["commit"] == git_sha.downcase
      end
    end

    def automated_build_status(repo:, git_sha:)
      builds = automated_builds_for(repo: repo, git_sha: git_sha)
      phases = builds.map { |b| b["phase"] }

      if !phases.include?("complete") && phases.include?("error")
        return :failed
      end

      if phases.include?("complete")
        return :finished
      else
        return :building
      end
    end

    def wait_for_automated_build(repo:, git_sha:, timeout: 3600)
      loop do
        status = automated_build_status(repo: repo, git_sha: git_sha)
        case status
        when :failed
          raise "The docker build failed"
        when :finished
          puts ""
          return
        when :building
          print '.'
          sleep 5
        end
      end
    end

    def docker_image_id_for_tag(repo:, tag:)
      resp = conn.get(
        path: "/repository/#{repo}/tag/",
        query_params: {
          "specificTag" => tag
        }
      )
      tags = resp["tags"]
      tags.find { |tag|
        tag["end_ts"].nil?
      }["docker_image_id"]
    end

    def put_tag(repo:, image_id:, tag:)
      conn.put(
        path: "/repository/#{repo}/tag/#{tag}",
        body: {
          image: image_id
        }
      )
    end
  end
end
