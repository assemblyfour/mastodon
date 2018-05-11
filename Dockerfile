FROM mastodon-base:latest

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
