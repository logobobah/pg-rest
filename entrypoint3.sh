#!/bin/bash
set -e
source ${PG_APP_HOME}/functions

[[ ${DEBUG} == true ]] && set -x

# allow arguments to be passed to postgres
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == postgres || ${1} == $(which postgres) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

#!/bin/bash

cat > /var/lib/postgresql/.walg.json << EOF
{
    "WALG_S3_PREFIX": "s3://${BACKET_NAME}",
    "AWS_ENDPOINT": "https://hb.bizmrg.com",
    "AWS_ACCESS_KEY_ID": "${KEY_ID}",
    "AWS_SECRET_ACCESS_KEY": "${SECRET_KOD}",
    "WALG_COMPRESSION_METHOD": "brotli",
    "WALG_DELTA_MAX_STEPS": "5",
    "PGDATA": "/var/lib/pgpro/1c-${PG_VERSION}/data",
    "PGHOST": "/tmp/.s.PGSQL.5432"
}
EOF
# обязательно меняем владельца файла:
chown postgres: /var/lib/postgresql/.walg.json

# default behaviour is to launch postgres
if [[ -z ${1} ]]; then
  map_uidgid

  create_datadir
  create_certdir
  create_logdir
  create_rundir

  set_resolvconf_perms

  configure_postgresql

  #настраиваем postgresql
  echo "wal_level=replica" >> ${PG_DATADIR}/postgresql.conf
  echo "archive_mode=on" >> ${PG_DATADIR}/postgresql.conf
  echo "archive_command='/usr/local/bin/wal-g wal-push \"%p\" >> /var/log/postgresql/archive_command.log 2>&1' " >> ${PG_DATADIR}/postgresql.conf
  echo "archive_timeout=60" >> ${PG_DATADIR}/postgresql.conf
  echo "restore_command='/usr/local/bin/wal-g wal-fetch \"%f\" \"%p\" >> /var/log/postgresql/restore_command.log 2>&1' " >> ${PG_DATADIR}/postgresql.conf
  
  mkdir /var/log/postgresql
  chown postgres:  -R /var/log/postgresql

  echo "Starting PostgreSQL ${PG_VERSION}..."
  exec start-stop-daemon --start --chuid ${PG_USER}:${PG_USER} \
    --exec ${PG_BINDIR}/postgres -- -D ${PG_DATADIR} ${EXTRA_ARGS}
  

  #su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password 'password';\""
else
  exec "$@"
fi
