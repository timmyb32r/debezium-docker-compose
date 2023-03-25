# debezium (postgres) with karapace schema-registry via confluent json serializer - test all 'value.subject.name.strategy' variants

## build docker image with

0. download confluent standalone jar files
    ```sh
    wget https://github.com/timmyb32r/debezium-docker-compose/releases/download/7.0.1/confluent-serializers-standalone-7.0.1.tar.gz && tar --strip-components=2 -xzf confluent-serializers-standalone-7.0.1.tar.gz && rm ./confluent-serializers-standalone-7.0.1.tar.gz
    ```

1. add to debezium:2.0 docker container these files
    ```sh
    docker build . -t timmyb32r/debezium:2.0
    ```

## demo

0) check TopicNameStrategy
    ```sh
    docker-compose up
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-karapace-json.00.json
    export PGPASSWORD='postgres' && psql -h localhost -p 5432 -U postgres -d postgres
    CREATE TABLE public.table_name(id INT PRIMARY KEY, val text);
    INSERT INTO public.table_name(id, val) VALUES (1, 'blablabla');
    \q
    kcat -b localhost:9092 -L
        ...
        topic "dbserver.public.table_name" with 1 partitions:
        ...
    clear && curl --silent -X GET http://localhost:8081/subjects | jq
        "dbserver.public.table_name-key",
        "dbserver.public.table_name-value"
    docker ps -a | awk '{print $1}' | xargs docker rm
    ```

1) check RecordNameStrategy
    ```sh
    docker-compose up
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-karapace-json.01.json
    export PGPASSWORD='postgres' && psql -h localhost -p 5432 -U postgres -d postgres
    CREATE TABLE public.table_name(id INT PRIMARY KEY, val text);
    INSERT INTO public.table_name(id, val) VALUES (1, 'blablabla');
    \q
    kcat -b localhost:9092 -L
        ...
        topic "dbserver.public.table_name" with 1 partitions:
        ...
    clear && curl --silent -X GET http://localhost:8081/subjects | jq
        "dbserver.public.table_name.Key",
        "dbserver.public.table_name.Envelope"
    docker ps -a | awk '{print $1}' | xargs docker rm
    ```

2) check TopicRecordNameStrategy
    ```sh
    docker-compose up
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-karapace-json.02.json
    export PGPASSWORD='postgres' && psql -h localhost -p 5432 -U postgres -d postgres
    CREATE TABLE public.table_name(id INT PRIMARY KEY, val text);
    INSERT INTO public.table_name(id, val) VALUES (1, 'blablabla');
    \q
    kcat -b localhost:9092 -L
        ...
        topic "dbserver.public.table_name" with 1 partitions:
        ...
    clear && curl --silent -X GET http://localhost:8081/subjects | jq
        "dbserver.public.table_name-dbserver.public.table_name.Key",
        "dbserver.public.table_name-dbserver.public.table_name.Envelope"
    docker ps -a | awk '{print $1}' | xargs docker rm
    ```

## Observation of subject name strategies

settings:
- "topic.prefix": "dbserver"
- "table.whitelist": "public.table_name"

names:
- recordname-key name: `dbserver.public.table_name.Key`
- recordname-value name: `dbserver.public.table_name.Envelope`
- topic-name: `dbserver.public.table_name`

so:
- TopicNameStrategy: %topic-name% with suffix: '-key'/'-value'
    key: `dbserver.public.table_name-key`
    val: `dbserver.public.table_name-value`
- RecordNameStrategy: %recordname-value%
    key: `dbserver.public.table_name.Key`
    val: `dbserver.public.table_name.Envelope`
- TopicRecordNameStrategy: %topic-name%-%recordname%
    key: `dbserver.public.table_name-dbserver.public.table_name.Key`
    key: `dbserver.public.table_name-dbserver.public.table_name.Envelope`

## how built this docker-compose

It's modified copy of 'debezium-schema-registry-pg-karapace-json'
