FROM ruby:3.2 AS builder
WORKDIR /app
COPY site/Gemfile site/Gemfile.lock ./
RUN bundle install
COPY site/ .
RUN bundle exec jekyll build

FROM nginx:alpine
COPY --from=builder /app/_site /usr/share/nginx/html