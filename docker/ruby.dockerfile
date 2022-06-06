FROM ruby:3
WORKDIR /code
COPY ./server/Gemfile /code/server/Gemfile
WORKDIR /code/server
RUN bundle install