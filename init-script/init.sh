#!/bin/bash
set -e

# Создаем роль в мастере
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DROP ROLE IF EXISTS replicator;
	CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'my_replicator_password';
    SELECT * FROM pg_create_physical_replication_slot('replication_slot_slave1');
EOSQL

# Делаем бекап мастера из которого будет поднят слейв
pg_basebackup -D /var/lib/postgresql/data-slave -S replication_slot_slave1 -X stream -P -U replicator -Fp -R

# Добавляем конфиг подключения к слоту репликации на слейве
cp /etc/postgresql/init-script/slave-config/* /var/lib/postgresql/data-slave
cp /etc/postgresql/init-script/config/pg_hba.conf /var/lib/postgresql/data