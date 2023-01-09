# debezium (postgres) with karapace schema-registry via confluent json serializer

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
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-karapace-json.json
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
        {"before":null,"after":{"id":1,"val":"blablabla"},"source":{"version":"2.0.1.Final","connector":"postgresql","name":"dbserver1","ts_ms":1673223652593,"snapshot":"false","db":"postgres","sequence":"[\"33976960\",\"33976960\"]","schema":"public","table":"timmyb32r_favourite_table","txId":754,"lsn":33976960,"xmin":null},"op":"c","ts_ms":1673223653030,"transaction":null}
    ```
    As we see - this json message is very compact relatively default huge json with embedded schema. Schema ID is stored just as in avro - in first 5 bytes of message (actually in 4 bytes after leading zero magic byte).

5) check key
    ```sh
    kcat -b localhost:9092 -C -o beginning -q -t dbserver1.public.timmyb32r_favourite_table -c 1 -K!
        {"schema":{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"}],"optional":false,"name":"dbserver1.public.timmyb32r_favourite_table.Key"},"payload":{"id":1}}!{"before":null,"after":{"id":1,"val":"blablabla"},"source":{"version":"2.0.1.Final","connector":"postgresql","name":"dbserver1","ts_ms":1673223652593,"snapshot":"false","db":"postgres","sequence":"[\"33976960\",\"33976960\"]","schema":"public","table":"timmyb32r_favourite_table","txId":754,"lsn":33976960,"xmin":null},"op":"c","ts_ms":1673223653030,"transaction":null}
    ```
    As we see - key is ok

6) check schema in schema registry
    ```
    curl --silent -X GET http://localhost:8081/schemas
    ```
    Actually here will be 6 schemas - 5 of them for some tutorial tables, and id=6 will be for our table


## notes:

- If you wanna watch schema evolution - for example, when you add column into database - set KARAPACE_COMPATIBILITY to one of next values: NONE,FORWARD,FORWARD_TRANSITIVE
- If you wanna watch requests to karapace - set KARAPACE_LOG_LEVEL to INFO


## how built this docker-compose

It's mix of karapace docker-compose & debezium postgres docker-compose

https://github.com/aiven/karapace/blob/main/container/docker-compose.yml
with next changes:
- KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true" - to allow debezium create topics

https://github.com/debezium/debezium-examples/blob/main/tutorial/docker-compose-postgres.yaml
with next changes:
- debezium docker image renamed to our 'timmyb32r/debezium:2.0' - where present confluent standalone jar files
- specify ${DEBEZIUM_VERSION} to 1.9, bcs from 2.0 there are no confluent classes in debezium docker image (see notes)
- added link to '- karapace-registry' for debezium docker image
- connect (debezium): BOOTSTRAP_SERVERS: 9092 -> 29092


## how to build standalone jar files

0. We need to know published versions in confluent maven-repository - we can see them in this maven-repo, in some package, for example: https://packages.confluent.io/maven/io/confluent/rest-utils-parent/
1. For example we choosed 7.0.1
2. Go to github confluentinc/schema-registry - Releases - and choose tag with exacly this version - for example: https://github.com/confluentinc/schema-registry/releases/tag/v7.0.1
3. Download tar.gz & build it with standalone profile (by java 11): 
    ```sh
    mvn package -P standalone -DskipTests
    ```


## requirements

- docker-compose
- curl
- psql
- kafkacat
- maven
- java 11 as default java

