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

#cat > /var/lib/postgresql/.walg.json << EOF
##{
#    "WALG_S3_PREFIX": "s3://${BACKET_NAME_R}",
#    "AWS_ENDPOINT": "https://hb.bizmrg.com",
#    "AWS_ACCESS_KEY_ID": "${KEY_ID_R}",
#    "AWS_SECRET_ACCESS_KEY": "${SECRET_KOD_R}",
#    "WALG_COMPRESSION_METHOD": "brotli",
#    "WALG_DELTA_MAX_STEPS": "5",
#    "PGDATA": "/var/lib/pgpro/1c-${PG_VERSION}/data",
#    "PGHOST": "/tmp/.s.PGSQL.5432"
#}
#EOF

if [[ ! -d ${PG_DATADIR} ]] ; then
   IsEmpty=1
   echo "${PG_DATADIR} is not exists"
elif [[  -d ${PG_DATADIR}  && -z "$(ls -A ${PG_DATADIR})" ]]; then
   IsEmpty=1
   echo "${PG_DATADIR} is Empty"
else
   IsEmpty=0
   #echo "${PG_DATADIR} is not empty"
   echo "устанавливаем права на папку кластера"
   chown -R postgres:postgres /var/lib/pgpro/1c-13/data
   chmod 700  /var/lib/pgpro/1c-13/data

   
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
   #chown -R postgres:postgres ${PG_DATADIR} 
   #chmod 700  ${PG_DATADIR} 
   echo "настроили права"
fi

#if [[  -d ${PG_DATADIR} ]] ; then
#  echo "настраиваем права 66"
#  chown -R postgres:postgres ${PG_DATADIR} 
#  chmod 700  ${PG_DATADIR} 
#fi

  

  
 
if [[ ${PG_RESTORE} = "restore" ]] && [[ ${IsEmpty} = 1 ]]; then

     configure_postgresql
    
     set_pgbackrest_param "repo1-s3-bucket" ${BACKET_NAME_R}
     set_pgbackrest_param "repo1-s3-key" ${KEY_ID_R}
     set_pgbackrest_param "repo1-s3-key-secret" ${SECRET_KOD_R}

     rm -rf ${PG_DATADIR}/*
     echo "востанавливаем данные"
     
     sudo -u postgres pgbackrest --stanza=demo  restore

     #echo "wal_level=replica" >> ${PG_DATADIR}/postgresql.conf
     #echo "archive_mode=off" >> ${PG_DATADIR}/postgresql.conf
     #chown -R postgres:postgres ${PG_DATADIR} 
     #chmod 700  ${PG_DATADIR} 
      
fi



 
if [[ ! -d /var/log/postgresql ]]; then
  mkdir /var/log/postgresql
fi
  
  chown postgres:  -R /var/log/postgresql
  

  
  configure_postgresql
#  chown -R postgres:postgres ${PG_DATADIR} 
#  chmod 700  ${PG_DATADIR} 
  echo "Starting PostgreSQL ${PG_VERSION}..."
  exec start-stop-daemon --start --chuid ${PG_USER}:${PG_USER} \
    --exec ${PG_BINDIR}/postgres -- -D ${PG_DATADIR} ${EXTRA_ARGS}
  
else
  exec "$@"
fi