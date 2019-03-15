FROM ruby:2.6

WORKDIR /app
ADD Gemfile /app/
ADD bcnd.gemspec /app/
RUN bundle install
ADD . /app
