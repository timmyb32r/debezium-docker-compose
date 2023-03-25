# debezium (postgres) with karapace schema-registry via confluent json serializer - with incompatible schemas, routed into one topic - DEMO HOW IT'S DOESN'T WORK

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
    CREATE TABLE public.timmyb32r_favourite_table0(id INT PRIMARY KEY, val text);
    CREATE TABLE public.timmyb32r_favourite_table1(id INT PRIMARY KEY, val INT);
    INSERT INTO public.timmyb32r_favourite_table0(id, val) VALUES (1, 'aaa');
    INSERT INTO public.timmyb32r_favourite_table1(id, val) VALUES (1, 1);
    \q
    ```

3) check debezium logs
    ```sh
    2023-03-25 19:32:00,676 ERROR  ||  WorkerSourceTask{id=timmyb32r-schema-registry-pg-karapace-json-connector-with-routing-into-one-table-0} Task threw an uncaught and unrecoverable exception. Task is being killed and will not recover until manually restarted   [org.apache.kafka.connect.runtime.WorkerTask]
    org.apache.kafka.connect.errors.ConnectException: Tolerance exceeded in error handler
        at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execAndHandleError(RetryWithToleranceOperator.java:223)
        at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execute(RetryWithToleranceOperator.java:149)
        at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.convertTransformedRecord(AbstractWorkerSourceTask.java:477)
        at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.sendRecords(AbstractWorkerSourceTask.java:387)
        at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.execute(AbstractWorkerSourceTask.java:354)
        at org.apache.kafka.connect.runtime.WorkerTask.doRun(WorkerTask.java:189)
        at org.apache.kafka.connect.runtime.WorkerTask.run(WorkerTask.java:244)
        at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.run(AbstractWorkerSourceTask.java:72)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515)
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628)
        at java.base/java.lang.Thread.run(Thread.java:829)
    Caused by: org.apache.kafka.connect.errors.DataException: Converting Kafka Connect data to byte[] failed due to serialization error of topic timmyb32r_server.timmyb32r_schema.timmyb32r_topic_name:
        at io.confluent.connect.json.JsonSchemaConverter.fromConnectData(JsonSchemaConverter.java:92)
        at org.apache.kafka.connect.storage.Converter.fromConnectData(Converter.java:64)
        at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.lambda$convertTransformedRecord$6(AbstractWorkerSourceTask.java:477)
        at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execAndRetry(RetryWithToleranceOperator.java:173)
        at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execAndHandleError(RetryWithToleranceOperator.java:207)
        ... 12 more
    Caused by: org.apache.kafka.common.errors.SerializationException: Error registering JSON schema: {"type":"object","title":"timmyb32r_server.timmyb32r_schema.timmyb32r_topic_name.Envelope","connect.version":1,"properties":{"op":{"type":"string","connect.index":3},"before":{"connect.index":0,"oneOf":[{"type":"null"},{"type":"object","title":"timmyb32r_server.timmyb32r_schema.timmyb32r_topic_name.Value","properties":{"val":{"connect.index":1,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int32"}]},"id":{"type":"integer","connect.index":0,"connect.type":"int32"}}}]},"after":{"connect.index":1,"oneOf":[{"type":"null"},{"type":"object","title":"timmyb32r_server.timmyb32r_schema.timmyb32r_topic_name.Value","properties":{"val":{"connect.index":1,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int32"}]},"id":{"type":"integer","connect.index":0,"connect.type":"int32"}}}]},"source":{"type":"object","title":"io.debezium.connector.postgresql.Source","connect.index":2,"properties":{"schema":{"type":"string","connect.index":7},"sequence":{"connect.index":6,"oneOf":[{"type":"null"},{"type":"string"}]},"xmin":{"connect.index":11,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"connector":{"type":"string","connect.index":1},"lsn":{"connect.index":10,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"name":{"type":"string","connect.index":2},"txId":{"connect.index":9,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"version":{"type":"string","connect.index":0},"ts_ms":{"type":"integer","connect.index":3,"connect.type":"int64"},"snapshot":{"connect.index":4,"oneOf":[{"type":"null"},{"type":"string","title":"io.debezium.data.Enum","default":"false","connect.version":1,"connect.parameters":{"allowed":"true,last,false,incremental"}}]},"db":{"type":"string","connect.index":5},"table":{"type":"string","connect.index":8}}},"ts_ms":{"connect.index":4,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"transaction":{"connect.index":5,"oneOf":[{"type":"null"},{"type":"object","title":"event.block","connect.version":1,"properties":{"data_collection_order":{"type":"integer","connect.index":2,"connect.type":"int64"},"id":{"type":"string","connect.index":0},"total_order":{"type":"integer","connect.index":1,"connect.type":"int64"}}}]}}}
        at io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe.toKafkaException(AbstractKafkaSchemaSerDe.java:259)
        at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.serializeImpl(AbstractKafkaJsonSchemaSerializer.java:141)
        at io.confluent.connect.json.JsonSchemaConverter$Serializer.serialize(JsonSchemaConverter.java:149)
        at io.confluent.connect.json.JsonSchemaConverter.fromConnectData(JsonSchemaConverter.java:90)
        ... 16 more
    Caused by: io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: Incompatible schema, compatibility_mode=FULL subschemas are incompatible; error code: 409
        at io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:297)
        at io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:367)
        at io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:544)
        at io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:532)
        at io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:490)
        at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.registerAndGetId(CachedSchemaRegistryClient.java:257)
        at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.register(CachedSchemaRegistryClient.java:366)
        at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.register(CachedSchemaRegistryClient.java:337)
        at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.serializeImpl(AbstractKafkaJsonSchemaSerializer.java:106)
        ... 18 more
    2023-03-25 19:32:00,676 INFO   ||  Stopping down connector   [io.debezium.connector.common.BaseSourceTask]
    ```
