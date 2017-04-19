require 'spec_helper'
require 'json'

describe Bcnd::Runner do
  before do
    ENV["TRAVIS"] = "true"
    ENV["GITHUB_TOKEN"] = "github_token"
    ENV["MAINLINE_APP_TOKEN"] = "mainline_app_token"
    ENV["STABLE_APP_TOKEN"] = "stable_app_token"
    ENV["QUAY_TOKEN"] = "quay_token"
    ENV["TRAVIS_COMMIT"] = "aaaaaa"
    ENV["TRAVIS_REPO_SLUG"] = "org/repo"
  end

  describe "#deploy" do
    context "when master branch" do
      before do
        ENV["TRAVIS_BRANCH"] = "master"
        ENV["TRAVIS_PULL_REQUEST"] = "false"
      end

      it "wait for quay build to be finished" do
        stub1 = stub_request(:get, "https://quay.io/api/v1/repository/org/repo/build/?limit=20").to_return(
          body: {
            builds: [
              {
                trigger_metadata: {
                  commit: "aaaaaa"
                },
                phase: "complete"
              }
            ]
          }.to_json
        )
        stub2 = stub_request(:get,  "https://quay.io/api/v1/repository/org/repo/tag/")
        .with(query: hash_including("specificTag" => "latest"))
        .to_return(
          body: {
            tags: [
              {
                end_ts: nil,
                docker_image_id: 'bbbbbb'
              }
            ]
          }.to_json
        )

        stub3 = stub_request(:put,   "https://quay.io/api/v1/repository/org/repo/tag/aaaaaa")
        .with(body: {image: "bbbbbb"}.to_json)

        runner = described_class.new
        expect(runner).to receive(:system).with("bcn deploy -e staging --tag aaaaaa --app-token mainline_app_token 1> /dev/null") do
          system 'true'
        end

        expect{runner.deploy}.to_not raise_error
        expect(stub1).to have_been_requested
        expect(stub2).to have_been_requested
        expect(stub3).to have_been_requested
      end
    end

    context "when production branch" do
      before do
        ENV["TRAVIS_BRANCH"] = "production"
        ENV["TRAVIS_PULL_REQUEST"] = "false"
      end

      it do
        expect_any_instance_of(Octokit::Client).to receive(:compare) do
          double(
            merge_base_commit: double(sha: 'aaaaaa')
          )
        end

        stub1 = stub_request(:get,  "https://quay.io/api/v1/repository/org/repo/tag/")
        .with(query: hash_including("specificTag" => "aaaaaa"))
        .to_return(
          body: {
            tags: [
              {
                end_ts: nil,
                docker_image_id: 'bbbbbb'
              }
            ]
          }.to_json
        )

        runner = described_class.new
        expect(runner).to receive(:system).with("bcn deploy -e production --tag aaaaaa --app-token stable_app_token 1> /dev/null") do
          system 'true'
        end
        expect{runner.deploy}.to_not raise_error
      end
    end
  end
end
