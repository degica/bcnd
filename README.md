# Barcelona Deployer

Degica's opinionated deploy pipeline tool

## Installation

```
gem 'bcnd'
```

## Prerequisites

bcnd is very opinionated about your development configurations.
So there are lots of requirements you need to prepare beforehand.

### Quay.io

You need quay.io as your docker image registry

### Barcelona

where your applications will be deployed

### GitHub

bcnd only supports GitHub as a source code repository.
Your GitHub repository must have 2 branches: mainline and stable
bcnd doesn't offer a customizability for the branch names.

#### mainline branch

a mainline branch includes all reviewed commits. By default mainline branch is `master`.
bcnd automatically deploys mainline branch to your mainline environment.

#### stable branch

a stable branch includes stable commits. By default stable branch is `production`.
bcnd automatically deploys stable branch to your stable environment.

### Webhooks

- webhook for quay.io automated builds
- webhook for your CI service

## Usage

Setup your CI configuration as follows:

- Install barcelona client
- Install bcnd
- Execute `bcnd` in your CI's "after success" script

Here's the example for travis CI

```yml
before_script:
- npm install -g barcelona
- gem install bcnd
script:
- bundle excec rspec
- bcnd
```

### Environment variables

Set the following environment variables to your CI build environment:

- `QUAY_TOKEN`
  - **Required**
  - a quay.io oauth token. you can create a new oauth token at quay.io organization page -> OAuth Applications -> Create New Application -> Generate Token
- `GITHUB_TOKEN`
  - **Conditional** If you have stable branch this is required.
  - a github oauth token which has a permission to read your application's repository
- `BARCELONA_ENDPOINT`
  - **Required**
  - A URL of Barcelona service e.g. `https://barcelona.your-domain.com`
- `MAINLINE_HERITAGE_TOKEN`
  - **Required**
  - Barcelona's heritage token for the mainline application
- `STABLE_HERITAGE_TOKEN`
  - **Conditional** If you have stable branch this is required.
  - Barcelona's heritage token for the stable application
- `QUAY_REPOSITORY`
  - **Optional**
  - A name of your quay repository. It should be `[organization]/[repo name]`. If you don't set this variable bcnd uses github repository name as a quay repository name.

### Configurations

You can customize mainline branch name, mainline environment(where mainline code is deployed), stable branch name, and stable environment with `barcelona.yml`

```yaml
# /barcelona.yml example
---
environments:
  # your barcelona configurations. bcnd doesn't touch this.
bcnd:
  mainline_branch: dev # default: master
  mainline_environment: dev # default: staging
  stable_branch: master # default: production
  stable_environment: master # default: production
```

## How It Works

### Deploying to a staging environment

When a commit is pushed into a mainline branch, bcnd deploys your application to barcelona's mainline environment.
Here's what bcnd actually does:

- Wait for quay.io automated build to be finished
- Attach a docker image tag to the `latest` docker image.
  - The tag is the latest mainline branch's commit hash
- Call Barcelona deploy API with the tag name
  - `bcn deploy -e [mainline env] --tag [git_commit_hash]`

### Deploying to a production environment

When a commit is pushed into a stable branch, bcnd deploys your application to barcelona's stable environment
Here's what bcnd actually does:

- Compare `master` and `production` branch
  - If there is a difference between the branches, bcnd raises an error
- Get master branch's latest commit hash
- Find a docker image from quay.io with the tag of the master commit hash
- Call Barcelona deploy API with the tag name
  - `bcn deploy -e [stable env] --tag [git_commit_hash]`
 
