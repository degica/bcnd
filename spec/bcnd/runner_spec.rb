require 'spec_helper'
require 'json'

describe Bcnd::Runner do
  describe "Travis CI" do
    before do
      stub_env("TRAVIS", "true")
      stub_env("GITHUB_TOKEN", "github_token")
      stub_env("MAINLINE_HERITAGE_TOKEN", "mainline_heritage_token")
      stub_env("STABLE_HERITAGE_TOKEN", "stable_heritage_token")
      stub_env("QUAY_TOKEN", "quay_token")
      stub_env("TRAVIS_COMMIT", "aaaaaa")
      stub_env("TRAVIS_REPO_SLUG", "org/repo")
    end

    context "when master branch" do
      before do
        stub_env("TRAVIS_BRANCH", "master")
        stub_env("TRAVIS_PULL_REQUEST", "false")
      end

      it "wait for quay build to be finished" do
        stub1 = stub_request(:get, "https://quay.io/api/v1/repository/org/repo/tag/")
                  .with(query: hash_including("specificTag" => "aaaaaa"))
                  .to_return(
                    body: {
                      tags: []
                    }.to_json
                  )
        stub2 = stub_request(:get, "https://quay.io/api/v1/repository/org/repo/build/?limit=20").to_return(
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
        stub3 = stub_request(:get, "https://quay.io/api/v1/repository/org/repo/tag/")
        .with(query: hash_including("specificTag" => "master"))
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

        stub4 = stub_request(:put,  "https://quay.io/api/v1/repository/org/repo/tag/aaaaaa")
        .with(body: {image: "bbbbbb"}.to_json)

        runner = described_class.new
        expect(runner).to receive(:system).with("bcn deploy -e staging --tag aaaaaa --heritage-token mainline_heritage_token 1> /dev/null") do
          system 'true'
        end

        expect{runner.deploy}.to_not raise_error
        expect(stub1).to have_been_requested
        expect(stub2).to have_been_requested
        expect(stub3).to have_been_requested
        expect(stub4).to have_been_requested
      end

      context "when the tag already exists" do
        it "skips tagging" do
          stub = stub_request(:get,  "https://quay.io/api/v1/repository/org/repo/tag/")
                   .with(query: hash_including("specificTag" => "aaaaaa"))
                   .to_return(
                     body: {
                       tags: [
                         {
                           "reversion" => false,
                           "manifest_digest" => "sha256:97b6de52ce9d9d89766144e0a9a0fe4a151741ecd812884ce804f41bdb672419",
                           "start_ts" => 1492592525,
                           "name" => "aaaaaa",
                           "docker_image_id" => "aacf174aa6cf1a9de0efb5e6164cbc2556965fa469e94725c0de596e1e01a2d1"
                         },
                       ]
                     }.to_json
                   )

          runner = described_class.new
          expect(runner).to receive(:system).with("bcn deploy -e staging --tag aaaaaa --heritage-token mainline_heritage_token 1> /dev/null") do
            system 'true'
          end
          expect{runner.deploy}.to_not raise_error
          expect(stub).to have_been_requested
        end
      end
    end

    context "when production branch" do
      before do
        stub_env("TRAVIS_BRANCH", "production")
        stub_env("TRAVIS_PULL_REQUEST", "false")
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
        expect(runner).to receive(:system).with("bcn deploy -e production --tag aaaaaa --heritage-token stable_heritage_token 1> /dev/null") do
          system 'true'
        end
        expect{runner.deploy}.to_not raise_error
      end
    end
  end

  describe "GitLab CI" do
    before do
      stub_env("GITLAB_CI", "true")
      stub_env("GITHUB_TOKEN", "github_token")
      stub_env("MAINLINE_HERITAGE_TOKEN", "mainline_heritage_token")
      stub_env("STABLE_HERITAGE_TOKEN", "stable_heritage_token")
      stub_env("QUAY_TOKEN", "quay_token")
      stub_env("CI_COMMIT_SHA", "aaaaaa")
      stub_env("CI_PROJECT_PATH", "org/repo")
    end

    context "when master branch" do
      before do
        stub_env("CI_COMMIT_REF_NAME", "master")
        stub_env("TRAVIS_PULL_REQUEST", nil)
      end

      it "wait for quay build to be finished" do
        stub1 = stub_request(:get, "https://quay.io/api/v1/repository/org/repo/tag/")
                  .with(query: hash_including("specificTag" => "aaaaaa"))
                  .to_return(
                    body: {
                      tags: []
                    }.to_json
                  )
        stub2 = stub_request(:get, "https://quay.io/api/v1/repository/org/repo/build/?limit=20").to_return(
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
        stub3 = stub_request(:get, "https://quay.io/api/v1/repository/org/repo/tag/")
        .with(query: hash_including("specificTag" => "master"))
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

        stub4 = stub_request(:put,  "https://quay.io/api/v1/repository/org/repo/tag/aaaaaa")
        .with(body: {image: "bbbbbb"}.to_json)

        runner = described_class.new
        expect(runner).to receive(:system).with("bcn deploy -e staging --tag aaaaaa --heritage-token mainline_heritage_token 1> /dev/null") do
          system 'true'
        end

        expect{runner.deploy}.to_not raise_error
        expect(stub1).to have_been_requested
        expect(stub2).to have_been_requested
        expect(stub3).to have_been_requested
        expect(stub4).to have_been_requested
      end

      context "when the tag already exists" do
        it "skips tagging" do
          stub = stub_request(:get,  "https://quay.io/api/v1/repository/org/repo/tag/")
                   .with(query: hash_including("specificTag" => "aaaaaa"))
                   .to_return(
                     body: {
                       tags: [
                         {
                           "reversion" => false,
                           "manifest_digest" => "sha256:97b6de52ce9d9d89766144e0a9a0fe4a151741ecd812884ce804f41bdb672419",
                           "start_ts" => 1492592525,
                           "name" => "aaaaaa",
                           "docker_image_id" => "aacf174aa6cf1a9de0efb5e6164cbc2556965fa469e94725c0de596e1e01a2d1"
                         },
                       ]
                     }.to_json
                   )

          runner = described_class.new
          expect(runner).to receive(:system).with("bcn deploy -e staging --tag aaaaaa --heritage-token mainline_heritage_token 1> /dev/null") do
            system 'true'
          end
          expect{runner.deploy}.to_not raise_error
          expect(stub).to have_been_requested
        end
      end
    end

    context "when production branch" do
      before do
        stub_env("CI_COMMIT_REF_NAME", "production")
        stub_env("TRAVIS_PULL_REQUEST", nil)
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
        expect(runner).to receive(:system).with("bcn deploy -e production --tag aaaaaa --heritage-token stable_heritage_token 1> /dev/null") do
          system 'true'
        end
        expect{runner.deploy}.to_not raise_error
      end
    end
  end
end
