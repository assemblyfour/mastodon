FROM ruby:2.4.3-alpine3.6

LABEL maintainer="https://github.com/tootsuite/mastodon" \
      description="Your self-hosted, globally interconnected microblogging community"

ENV RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production NODE_ENV=production

ARG YARN_VERSION=1.3.2
ARG YARN_DOWNLOAD_SHA256=6cfe82e530ef0837212f13e45c1565ba53f5199eec2527b85ecbcd88bf26821d
ARG LIBICONV_VERSION=1.15
ARG LIBICONV_DOWNLOAD_SHA256=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

EXPOSE 3000 4000

WORKDIR /mastodon

RUN apk -U upgrade \
 && apk add -t build-dependencies \
    build-base \
    icu-dev \
    libidn-dev \
    libressl \
    libtool \
    postgresql-dev \
    protobuf-dev \
    python \
 && apk add \
    ca-certificates \
    ffmpeg \
    file \
    git \
    icu-libs \
    imagemagick \
    libidn \
    libpq \
    nodejs \
    nodejs-npm \
    protobuf \
    tini \
    tzdata \
    less \
 && update-ca-certificates \
 && mkdir -p /tmp/src /opt \
 && wget -O yarn.tar.gz "https://github.com/yarnpkg/yarn/releases/download/v$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
 && echo "$YARN_DOWNLOAD_SHA256 *yarn.tar.gz" | sha256sum -c - \
 && tar -xzf yarn.tar.gz -C /tmp/src \
 && rm yarn.tar.gz \
 && mv /tmp/src/yarn-v$YARN_VERSION /opt/yarn \
 && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
 && wget -O libiconv.tar.gz "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz" \
 && echo "$LIBICONV_DOWNLOAD_SHA256 *libiconv.tar.gz" | sha256sum -c - \
 && tar -xzf libiconv.tar.gz -C /tmp/src \
 && rm libiconv.tar.gz \
 && cd /tmp/src/libiconv-$LIBICONV_VERSION \
 && ./configure --prefix=/usr/local \
 && make -j$(getconf _NPROCESSORS_ONLN)\
 && make install \
 && libtool --finish /usr/local/lib \
 && cd /mastodon \
 && rm -rf /tmp/* /var/cache/apk/*

RUN mkdir -p /mastodon/public/system /mastodon/public/assets /mastodon/public/packs

RUN gem install foreman

COPY package.json yarn.lock .yarnclean /mastodon/

RUN yarn --pure-lockfile \
 && yarn cache clean

COPY Gemfile Gemfile.lock /mastodon/

RUN bundle config build.nokogiri --with-iconv-lib=/usr/local/lib --with-iconv-include=/usr/local/include \
 && bundle install -j$(getconf _NPROCESSORS_ONLN) --deployment --without test development


COPY bin /mastodon/bin/
COPY public /mastodon/public/
COPY config /mastodon/config/
COPY app/javascript /mastodon/app/javascript/
COPY Rakefile /mastodon/
COPY app/lib /mastodon/app/lib/
COPY lib /mastodon/lib/
COPY app/controllers/application_controller.rb /mastodon/app/controllers/
COPY app/controllers/concerns /mastodon/app/controllers/concerns/
COPY app/validators /mastodon/app/validators/
COPY app/models/user.rb app/models/setting.rb app/models/application_record.rb /mastodon/app/models/
COPY app/models/concerns /mastodon/app/models/concerns/
COPY jest.config.js .eslintignore .eslintrc.yml .babelrc .postcssrc.yml /mastodon/
COPY app/views/errors /mastodon/app/views/errors/
COPY app/views/layouts/error.html.haml /mastodon/app/views/layouts/

RUN bundle exec rails assets:precompile RAILS_ENV=production OTP_SECRET=fake SECRET_KEY_BASE=fake

COPY . /mastodon

RUN chgrp -R 0 /mastodon /tmp
RUN chmod -R g=u /mastodon /tmp

USER 10001

ENTRYPOINT ["/sbin/tini", "--"]
