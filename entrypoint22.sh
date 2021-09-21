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
    "WALG_S3_PREFIX": "s3://${BACKET_NAME_R}",
    "AWS_ENDPOINT": "https://hb.bizmrg.com",
    "AWS_ACCESS_KEY_ID": "${KEY_ID_R}",
    "AWS_SECRET_ACCESS_KEY": "${SECRET_KOD_R}",
    "WALG_COMPRESSION_METHOD": "brotli",
    "WALG_DELTA_MAX_STEPS": "5",
    "PGDATA": "/var/lib/pgpro/1c-${PG_VERSION}/data",
    "PGHOST": "/tmp/.s.PGSQL.5432"
}
EOF
# обязательно меняем владельца файла:
chown postgres: /var/lib/postgresql/.walg.json

if [[ ! -d ${PG_DATADIR} ]] ; then
   IsEmpty=1
   echo "${PG_DATADIR} is not exists"
elif [[  -d ${PG_DATADIR}  && -z "$(ls -A ${PG_DATADIR})" ]]; then
   IsEmpty=1
   echo "${PG_DATADIR} is Empty"
else
   IsEmpty=0
   chown -R postgres:postgres /var/lib/pgpro/1c-13/data
   chmod 700  /var/lib/pgpro/1c-13/data

   echo "${PG_DATADIR} is not Empty"
fi

# default behaviour is to launch postgres
if [[ -z ${1} ]]; then
  map_uidgid

  create_datadir
  create_certdir
  create_logdir
  create_rundir

  set_resolvconf_perms

if [[ ${IsEmpty} = "0" ]]; then
   echo "настраиваем права"
   chown -R postgres:postgres ${PG_DATADIR} 
   chmod 700  ${PG_DATADIR} 
fi

 
  configure_postgresql
  
 
if [[ ${PG_RESTORE} = "restore" ]] && [[ ${IsEmpty} = 1 ]]; then
     [[ ! -d ${PG_DATADIR} ]] && mkdir /var/lib/pgpro/1c-13/data
     rm -rf /var/lib/pgpro/1c-13/data
     su - postgres -c '/usr/local/bin/wal-g backup-fetch /var/lib/pgpro/1c-13/data LATEST'
     su - postgres -c 'touch /var/lib/pgpro/1c-13/data/recovery.signal' 
    
     chown -R postgres:postgres ${PG_DATADIR} 
     chmod 700  ${PG_DATADIR}  
     
     configure_postgresql

     echo "delete file .walg.json"

     su - postgres -c 'rm /var/lib/postgresql/.walg.json'
     rm /var/lib/postgresql/.walg.json

  cat > /var/lib/postgresql/.walg.json << EOF
  {
      "WALG_S3_PREFIX": "${BACKET_NAME_A}",
      "AWS_ENDPOINT": "https://hb.bizmrg.com",
      "AWS_ACCESS_KEY_ID": "${KEY_ID_A}",
      "AWS_SECRET_ACCESS_KEY": "${SECRET_KOD_A}",
      "WALG_COMPRESSION_METHOD": "brotli",
      "WALG_DELTA_MAX_STEPS": "5",
      "PGDATA": "/var/lib/pgpro/1c-${PG_VERSION}/data",
      "PGHOST": "/tmp/.s.PGSQL.5432"
  }
EOF

  # обязательно меняем владельца файла:
  chown postgres: /var/lib/postgresql/.walg.json

     echo "wal_level=minimal" >> ${PG_DATADIR}/postgresql.conf
     echo "archive_mode=off" >> ${PG_DATADIR}/postgresql.conf


else
     configure_postgresql

     #настраиваем postgresql
     echo "wal_level=replica" >> ${PG_DATADIR}/postgresql.conf
     echo "archive_mode=on" >> ${PG_DATADIR}/postgresql.conf
     echo "archive_command='/usr/local/bin/wal-g wal-push \"%p\" >> /var/log/postgresql/archive_command.log 2>&1' " >> ${PG_DATADIR}/postgresql.conf
     echo "archive_timeout=60" >> ${PG_DATADIR}/postgresql.conf
     echo "restore_command='/usr/local/bin/wal-g wal-fetch \"%f\" \"%p\" >> /var/log/postgresql/restore_command.log 2>&1' " >> ${PG_DATADIR}/postgresql.conf
 
fi
 
if [[ ! -d /var/log/postgresql ]]; then
  mkdir /var/log/postgresql
fi
  
  chown postgres:  -R /var/log/postgresql

  echo "Starting PostgreSQL ${PG_VERSION}..."
  exec start-stop-daemon --start --chuid ${PG_USER}:${PG_USER} \
    --exec ${PG_BINDIR}/postgres -- -D ${PG_DATADIR} ${EXTRA_ARGS}
  

  #su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password 'password';\""
else
  exec "$@"
fi