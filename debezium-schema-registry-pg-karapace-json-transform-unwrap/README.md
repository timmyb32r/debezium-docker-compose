# debezium (postgres) with karapace schema-registry via confluent json serializer (+ transform unwrap)

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

0) run docker-compose
    ```sh
    docker-compose up
    ```

1) register & run debezium kafka-connector
    ```sh
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-karapace-json-transform-unwrap.json
    ```

2) create table & insert one record
    ```
    export PGPASSWORD='postgres' && psql -h localhost -p 5432 -U postgres -d postgres
    CREATE TABLE public.timmyb32r_favourite_table(id INT PRIMARY KEY, val text);
    INSERT INTO public.timmyb32r_favourite_table(id, val) VALUES (1, 'blablabla');
    \q
    ```

3) check if topic created
    ```sh
    > kcat -b localhost:9092 -L
      ...
      topic "dbserver1.public.timmyb32r_favourite_table" with 1 partitions:
          partition 0, leader 1, replicas: 1, isrs: 1
    ```

4) read message from kafka with schema registry
    ```
    kcat -b localhost:9092 -C -o beginning -q -t dbserver1.public.timmyb32r_favourite_table -c 1
        returns 5 non-human-readable bytes (first byte is a magic byte, next 4 bytes represent the schema id in big endian) + json + "\n" (last byte somewhy always new line byte):
        0x00 0x00 0x00 0x00 0x06 {"id":1,"val":"blablabla"}
    ```

5) check schema in schema registry
    ```
    curl --silent -X GET http://localhost:8081/schemas/ids/6
        {"schema": "{\"properties\": {\"id\": {\"connect.index\": 0, \"connect.type\": \"int32\", \"type\": \"integer\"}, \"val\": {\"connect.index\": 1, \"oneOf\": [{\"type\": \"null\"}, {\"type\": \"string\"}]}}, \"title\": \"dbserver1.public.timmyb32r_favourite_table.Value\", \"type\": \"object\"}", "schemaType": "JSON"}
    ```
    if pass though 'jq' field "schema" - we get clear and short schema description:
    ```
    {
        "properties": {
            "id": {
                "connect.index": 0,
                "connect.type": "int32",
                "type": "integer"
            },
            "val": {
                "connect.index": 1,
                "oneOf": [
                    {
                        "type": "null"
                    },
                    {
                        "type": "string"
                    }
                ]
            }
        },
        "title": "dbserver1.public.timmyb32r_favourite_table.Value",
        "type": "object"
    }
    ```

## notes:

- If you wanna watch schema evolution - for example, when you add column into database - set KARAPACE_COMPATIBILITY to one of next values: NONE,FORWARD,FORWARD_TRANSITIVE
- If you wanna watch requests to karapace - set KARAPACE_LOG_LEVEL to INFO


## how built this docker-compose

From 'debezium-schema-registry-pg-karapace-json', added transform unwrap


## how to build standalone jar files

see 'debezium-schema-registry-pg-karapace-json'


## requirements

- docker-compose
- curl
- psql
- kafkacat
