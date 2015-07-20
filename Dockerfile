FROM ruby:2.2.2

ADD . /app
RUN cd /app && bundle install
WORKDIR /app

ENTRYPOINT ["bundle","exec","ruby","app.rb"]
