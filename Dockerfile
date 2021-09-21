FROM ubuntu:focal

#MAINTAINER logobobah@gmail.com

ENV PG_APP_HOME=/etc/docker-postgresql \
    PG_VERSION=13 \
    PG_USER=postgres \
    PG_PASSWORD=password \
    PG_HOME=/var/lib/pgpro \
    PG_CERTDIR=/etc/postgresql/certs

    
ENV PG_BINDIR=/opt/pgpro/1c-${PG_VERSION}/bin \
    PG_DATADIR=${PG_HOME}/1c-${PG_VERSION}/data \
    PG_RUNDIR=/opt/pgpro/1c-${PG_VERSION} \
    PG_LOGDIR=log
    

RUN apt-get update && apt-get install -y sudo locales wget gnupg2 curl libpq-dev \
        && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
        && update-locale LANG=ru_RU.UTF-8 \
	&& ln -s /usr/lib/locale/en_US.utf8 /usr/lib/locale/en_US \
        && ln -s /usr/share/locale/en /usr/share/locale/en_US

ENV LANG ru_RU.UTF-8
#ENV PG_VERSION=13


RUN wget --quiet -O - http://repo.postgrespro.ru/pg1c-${PG_VERSION}/keys/GPG-KEY-POSTGRESPRO | apt-key add - \
 && echo 'deb http://repo.postgrespro.ru/pg1c-13/ubuntu/ focal main' > /etc/apt/sources.list.d/pg1c-13.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y acl \
      postgrespro-1c-${PG_VERSION} postgrespro-1c-${PG_VERSION}-client postgrespro-1c-${PG_VERSION}-contrib \
 && rm -rf ${PG_HOME} \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir /etc/docker-postgresql  \
   && mkdir -p /etc/pgbackrest  \
   && mkdir -p /etc/pgbackrest/conf.d \
   && mkdir -p -m 770 /var/log/pgbackrest \
   && chown postgres:postgres /var/log/pgbackrest  \
   && mkdir -p /var/run/postgresql/  \
   && chown postgres:postgres /var/run/postgresql \
   && mkdir -p /var/lib/pgbackrest  \
   && chmod 750 /var/lib/pgbackrest \
   && chown postgres:postgres /var/lib/pgbackrest


COPY pgbackrest /usr/bin/pgbackrest
COPY pgbackrest.conf  /etc/pgbackrest

RUN chmod 640 /etc/pgbackrest/pgbackrest.conf  \
   && chown postgres:postgres /etc/pgbackrest/pgbackrest.conf \
   && chmod 755 /usr/bin/pgbackrest 

COPY runtime/ ${PG_APP_HOME}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 5432/tcp
VOLUME ["${PG_HOME}", "${PG_RUNDIR}"]
WORKDIR /sbin

ENTRYPOINT ["/sbin/entrypoint.sh"]


