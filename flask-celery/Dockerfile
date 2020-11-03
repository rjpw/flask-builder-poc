FROM node:boron

RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  poppler-utils \
  python-dev \
  python-pip \
  python-pygments \
  rsync \
	&& rm -rf /var/lib/apt/lists/*

ENV HUGO_VERSION 0.19
ENV HUGO_BINARY hugo_${HUGO_VERSION}-64bit.deb

ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} /tmp/hugo.deb
RUN dpkg -i /tmp/hugo.deb \
	&& rm /tmp/hugo.deb

ENV CELERY_BROKER_URL redis://redis:6379/0
ENV CELERY_RESULT_BACKEND redis://redis:6379/0
ENV C_FORCE_ROOT true

# copy source code
COPY . /home/node/flask-celery
RUN chown -R 1000:1000 /home/node/flask-celery

WORKDIR /home/node/flask-celery

# install requirements
RUN pip install -r requirements.txt

USER node

# run the worker
ENTRYPOINT ["celery", "-A", "tasks", "worker", "--loglevel=info"]
