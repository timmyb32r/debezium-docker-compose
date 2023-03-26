# debezium postgres->kafka CDC with apicurio schema registry

## demo

0) run docker-compose
    ```sh
    export DEBEZIUM_VERSION=2.0 && docker-compose up
    ```

1) register & run debezium kafka-connector
    ```sh
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres.json
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

4) read message from kafka
    ```sh
    kcat -b localhost:9092 -C -t dbserver1.public.timmyb32r_favourite_table >./z.bin
    ```
    As we see - everything is here!

5) list schemas in apicurio schema registry
    ```sh
    curl --silent -X GET http://localhost:8080/api/search/artifacts | jq
    {
      "artifacts": [
        {
          "id": "dbserver1.public.timmyb32r_favourite_table-key",
          "createdOn": 1679859637875,
          "createdBy": "",
          "type": "KCONNECT",
          "state": "ENABLED",
          "modifiedOn": 1679859637875,
          "modifiedBy": ""
        },
        {
          "id": "dbserver1.public.timmyb32r_favourite_table-value",
          "createdOn": 1679859638080,
          "createdBy": "",
          "type": "KCONNECT",
          "state": "ENABLED",
          "modifiedOn": 1679859638080,
          "modifiedBy": ""
        }
      ],
      "count": 2
    }
    ```

## QUESTION

Where is [wire_format](https://docs.confluent.io/5.2.0/schema-registry/serializer-formatter.html#wire-format) or something?

Every schema registry (except google pub/sub) has own wire format:
- confluent
- azure
- cloudera
- aws glue

there are also exists some parameter (but it still don't add wire format): "value.converter.apicurio.registry.as-confluent": "true"

## how built this docker-compose

It's modified copy of debezium-pg & docker-compose-mysql-apicurio.yaml (from debezium tutorials)
