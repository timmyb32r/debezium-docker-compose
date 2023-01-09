# debezium (postgres) with karapace schema-registry via confluent avro serializer

## demo

0) run docker-compose
    ```sh
    docker-compose up
    ```

1) register & run debezium kafka-connector
    ```sh
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-karapace-avro.json
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
      topic "fullfillment.public.timmyb32r_favourite_table" with 1 partitions:
          partition 0, leader 1, replicas: 1, isrs: 1
    ```

4) read message from kafka with schema registry
    ```
    kcat -b localhost:9092 -C -o beginning -q -s value=avro -r http://localhost:8081 -t fullfillment.public.timmyb32r_favourite_table -c 1
        {"before": null, "after": {"Value": {"id": 1, "val": {"string": "blablabla"}}}, "source": {"version": "1.9.7.Final", "connector": "postgresql", "name": "fullfillment", "ts_ms": 1673184677727, "snapshot": {"string": "false"}, "db": "postgres", "sequence": {"string": "[\"37124064\",\"37124120\"]"}, "schema": "public", "table": "timmyb32r_favourite_table", "txId": {"long": 766}, "lsn": {"long": 37124120}, "xmin": null}, "op": "c", "ts_ms": {"long": 1673184678296}, "transaction": null}
    ```
    As we see - data decoded from avro (via schema-registry) successfully. Schema ID is stored in first 5 bytes of message (actually in 4 bytes after leading zero magic byte) - kcat just do GET /schemas/ids/1.
    
5) read raw binary avro data
    ```sh
    kcat -b localhost:9092 -C -o beginning -q -t fullfillment.public.timmyb32r_favourite_table -c 1
        *some-binary-stuff*
    ```
    As we see - it's really some binary mess

6) check key (despite of 'value', 'key' should be serialized as string)
    ```sh
    kcat -b localhost:9092 -C -o beginning -q -t fullfillment.public.timmyb32r_favourite_table -c 1 -K!
        {"schema":{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"}],"optional":false,"name":"fullfillment.public.timmyb32r_favourite_table.Key"},"payload":{"id":1}}!*some-binary-stuff*
    ```
    As we see - key is human-readable json-string (default key serializer)

7) check schema in schema registry
    ```
    curl --silent -X GET http://localhost:8081/schemas
        [{"id": 1, "schema": "{\"connect.name\": \"fullfillment.public.timmyb32r_favourite_table.Envelope\", \"fields\": [{\"default\": null, \"name\": \"before\", \"type\": [\"null\", {\"connect.name\": \"fullfillment.public.timmyb32r_favourite_table.Value\", \"fields\": [{\"name\": \"id\", \"type\": \"int\"}, {\"default\": null, \"name\": \"val\", \"type\": [\"null\", \"string\"]}], \"name\": \"Value\", \"type\": \"record\"}]}, {\"default\": null, \"name\": \"after\", \"type\": [\"null\", \"Value\"]}, {\"name\": \"source\", \"type\": {\"connect.name\": \"io.debezium.connector.postgresql.Source\", \"fields\": [{\"name\": \"version\", \"type\": \"string\"}, {\"name\": \"connector\", \"type\": \"string\"}, {\"name\": \"name\", \"type\": \"string\"}, {\"name\": \"ts_ms\", \"type\": \"long\"}, {\"default\": \"false\", \"name\": \"snapshot\", \"type\": [{\"connect.default\": \"false\", \"connect.name\": \"io.debezium.data.Enum\", \"connect.parameters\": {\"allowed\": \"true,last,false,incremental\"}, \"connect.version\": 1, \"type\": \"string\"}, \"null\"]}, {\"name\": \"db\", \"type\": \"string\"}, {\"default\": null, \"name\": \"sequence\", \"type\": [\"null\", \"string\"]}, {\"name\": \"schema\", \"type\": \"string\"}, {\"name\": \"table\", \"type\": \"string\"}, {\"default\": null, \"name\": \"txId\", \"type\": [\"null\", \"long\"]}, {\"default\": null, \"name\": \"lsn\", \"type\": [\"null\", \"long\"]}, {\"default\": null, \"name\": \"xmin\", \"type\": [\"null\", \"long\"]}], \"name\": \"Source\", \"namespace\": \"io.debezium.connector.postgresql\", \"type\": \"record\"}}, {\"name\": \"op\", \"type\": \"string\"}, {\"default\": null, \"name\": \"ts_ms\", \"type\": [\"null\", \"long\"]}, {\"default\": null, \"name\": \"transaction\", \"type\": [\"null\", {\"fields\": [{\"name\": \"id\", \"type\": \"string\"}, {\"name\": \"total_order\", \"type\": \"long\"}, {\"name\": \"data_collection_order\", \"type\": \"long\"}], \"name\": \"ConnectDefault\", \"namespace\": \"io.confluent.connect.avro\", \"type\": \"record\"}]}], \"name\": \"Envelope\", \"namespace\": \"fullfillment.public.timmyb32r_favourite_table\", \"type\": \"record\"}", "schemaType": "AVRO", "subject": "fullfillment.public.timmyb32r_favourite_table-value", "version": 1}]
    ```
    As we see - schema is into the schema-registry


## notes:

- If you wanna watch schema evolution - for example, when you add column into database - set KARAPACE_COMPATIBILITY to one of next values: NONE,FORWARD,FORWARD_TRANSITIVE
- If you wanna watch requests to karapace - set KARAPACE_LOG_LEVEL to INFO
- If you want to use debezium version higher than 1.9 - you should build docker image with confluent serializer classes - see schema-registry-karapace-json


## how built this docker-compose

It's mix of karapace docker-compose & debezium postgres docker-compose

https://github.com/aiven/karapace/blob/main/container/docker-compose.yml
with next changes:
- KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true" - to allow debezium create topics

https://github.com/debezium/debezium-examples/blob/main/tutorial/docker-compose-postgres.yaml
with next changes:
- specify ${DEBEZIUM_VERSION} to 1.9, bcs from 2.0 there are no confluent classes in debezium docker image (see notes)
- added link to '- karapace-registry' for debezium docker image
- connect (debezium): BOOTSTRAP_SERVERS: 9092 -> 29092


## requirements

- docker-compose
- curl
- psql
- kafkacat

