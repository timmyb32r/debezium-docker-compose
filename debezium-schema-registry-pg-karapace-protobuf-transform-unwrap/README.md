# debezium (postgres) with karapace schema-registry via confluent protobuf serializer (+ transform unwrap)

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
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-karapace-protobuf-transform-unwrap.json
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
        returns:
        - 5 non-human-readable bytes (first byte is a magic byte, next 4 bytes represent the schema id in big endian) 
        - 0x00 message index
        - protobuf message
        - "\n" (last byte somewhy always new line byte):
        0x00 0x00 0x00 0x00 0x06 0x00 0x08 0x01 0x12 0x09 blablabla "\n"
            0x08 0x01 - it's VARINT (field_num=1) with value 1
            0x12 0x09 blablabla - it's LEN (field_num=2) with length=9, with value: "blablabla"
    ```

5) check schema in schema registry
    ```
    curl --silent -X GET http://localhost:8081/schemas/ids/6
        {"schema": "syntax = \"proto3\";\npackage dbserver1.public.timmyb32r_favourite_table;\n\nmessage Value {\n  int32 id = 1;\n  string val = 2;\n}\n", "schemaType": "PROTOBUF"}
    ```
    if pass though 'jq' field "schema" - we get clear and short proto description:
    ```
    syntax = \"proto3\";
    package dbserver1.public.timmyb32r_favourite_table;

    message Value {
        int32 id = 1;
        string val = 2;
    }
    ```

## messages indexes

[description in habr article (RU)](https://habr.com/ru/company/lenta_utkonos_tech/blog/715298/)
[description in confluent documentation (EN)](https://docs.confluent.io/platform/current/schema-registry/serdes-develop/index.html#wire-format)

## how built this docker-compose

From 'debezium-schema-registry-pg-karapace-json-transform-unwrap', changed "value.converter" parameter


## how to build standalone jar files

see 'debezium-schema-registry-pg-karapace-json'


## requirements

- docker-compose
- curl
- psql
- kafkacat
