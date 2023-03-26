# debezium postgres->kafka with apicurio schema registry and confluent serializer

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

3) debezium got an error
    ```sh
    [187] STATEMENT:  START_REPLICATION SLOT "debezium" LOGICAL 0/203F390
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:52,372 INFO   Postgres|dbserver1|streaming  Requested thread factory for connector PostgresConnector, id = dbserver1 named = keep-alive   [io.debezium.util.Threads]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:52,372 INFO   Postgres|dbserver1|streaming  Creating thread debezium-postgresconnector-dbserver1-keep-alive   [io.debezium.util.Threads]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:52,373 INFO   Postgres|dbserver1|streaming  Processing messages   [io.debezium.connector.postgresql.PostgresStreamingChangeEventSource]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:52,376 INFO   Postgres|dbserver1|streaming  Message with LSN 'LSN{0/2070278}' arrived, switching off the filtering   [io.debezium.connector.postgresql.connection.WalPositionLocator]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:52,874 INFO   ||  1 records sent during previous 00:00:13.985, last recorded offset of {server=dbserver1} partition is {transaction_id=null, lsn_proc=34177264, lsn_commit=34177264, lsn=34177264, txId=762, ts_usec=1679862531855610}   [io.debezium.connector.common.BaseSourceTask]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-apicurio-1   | 2023-03-26 20:28:53 INFO <_> [io.apicurio.common.apps.logging.audit.AuditLogService] (executor-thread-2) apicurio.audit action="request" result="failure" src_ip="null" path="/apis/ccompat/v7/subjects/dbserver1.public.timmyb32r_favourite_table-value/versions" response_code="404" method="POST" user=""
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-apicurio-1   | 2023-03-26 20:28:53 WARN <_> [io.sentry.dsn.Dsn] (executor-thread-2) *** Couldn't find a suitable DSN, Sentry operations will do nothing! See documentation: https://docs.sentry.io/clients/java/ ***
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-apicurio-1   | 2023-03-26 20:28:53 WARN <_> [io.sentry.DefaultSentryClientFactory] (executor-thread-2) No 'stacktrace.app.packages' was configured, this option is highly recommended as it affects stacktrace grouping and display on Sentry. See documentation: https://docs.sentry.io/clients/java/config/#in-application-stack-frames
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,128 ERROR  ||  WorkerSourceTask{id=timmyb32r-schema-registry-pg-apicurio-with-confluent-serializer-0} Task threw an uncaught and unrecoverable exception. Task is being killed and will not recover until manually restarted   [org.apache.kafka.connect.runtime.WorkerTask]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | org.apache.kafka.connect.errors.ConnectException: Tolerance exceeded in error handler
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execAndHandleError(RetryWithToleranceOperator.java:223)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execute(RetryWithToleranceOperator.java:149)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.convertTransformedRecord(AbstractWorkerSourceTask.java:477)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.sendRecords(AbstractWorkerSourceTask.java:387)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.execute(AbstractWorkerSourceTask.java:354)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.WorkerTask.doRun(WorkerTask.java:189)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.WorkerTask.run(WorkerTask.java:244)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.run(AbstractWorkerSourceTask.java:72)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at java.base/java.lang.Thread.run(Thread.java:829)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | Caused by: org.apache.kafka.connect.errors.DataException: Converting Kafka Connect data to byte[] failed due to serialization error of topic dbserver1.public.timmyb32r_favourite_table:
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.connect.json.JsonSchemaConverter.fromConnectData(JsonSchemaConverter.java:92)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.storage.Converter.fromConnectData(Converter.java:64)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.AbstractWorkerSourceTask.lambda$convertTransformedRecord$6(AbstractWorkerSourceTask.java:477)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execAndRetry(RetryWithToleranceOperator.java:173)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at org.apache.kafka.connect.runtime.errors.RetryWithToleranceOperator.execAndHandleError(RetryWithToleranceOperator.java:207)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	... 12 more
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | Caused by: org.apache.kafka.common.errors.SerializationException: Error registering JSON schema: {"type":"object","title":"dbserver1.public.timmyb32r_favourite_table.Envelope","connect.version":1,"properties":{"op":{"type":"string","connect.index":3},"before":{"connect.index":0,"oneOf":[{"type":"null"},{"type":"object","title":"dbserver1.public.timmyb32r_favourite_table.Value","properties":{"val":{"connect.index":1,"oneOf":[{"type":"null"},{"type":"string"}]},"id":{"type":"integer","connect.index":0,"connect.type":"int32"}}}]},"after":{"connect.index":1,"oneOf":[{"type":"null"},{"type":"object","title":"dbserver1.public.timmyb32r_favourite_table.Value","properties":{"val":{"connect.index":1,"oneOf":[{"type":"null"},{"type":"string"}]},"id":{"type":"integer","connect.index":0,"connect.type":"int32"}}}]},"source":{"type":"object","title":"io.debezium.connector.postgresql.Source","connect.index":2,"properties":{"schema":{"type":"string","connect.index":7},"sequence":{"connect.index":6,"oneOf":[{"type":"null"},{"type":"string"}]},"xmin":{"connect.index":11,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"connector":{"type":"string","connect.index":1},"lsn":{"connect.index":10,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"name":{"type":"string","connect.index":2},"txId":{"connect.index":9,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"version":{"type":"string","connect.index":0},"ts_ms":{"type":"integer","connect.index":3,"connect.type":"int64"},"snapshot":{"connect.index":4,"oneOf":[{"type":"null"},{"type":"string","title":"io.debezium.data.Enum","default":"false","connect.version":1,"connect.parameters":{"allowed":"true,last,false,incremental"}}]},"db":{"type":"string","connect.index":5},"table":{"type":"string","connect.index":8}}},"ts_ms":{"connect.index":4,"oneOf":[{"type":"null"},{"type":"integer","connect.type":"int64"}]},"transaction":{"connect.index":5,"oneOf":[{"type":"null"},{"type":"object","title":"event.block","connect.version":1,"properties":{"data_collection_order":{"type":"integer","connect.index":2,"connect.type":"int64"},"id":{"type":"string","connect.index":0},"total_order":{"type":"integer","connect.index":1,"connect.type":"int64"}}}]}}}
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe.toKafkaException(AbstractKafkaSchemaSerDe.java:259)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.serializeImpl(AbstractKafkaJsonSchemaSerializer.java:141)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.connect.json.JsonSchemaConverter$Serializer.serialize(JsonSchemaConverter.java:149)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.connect.json.JsonSchemaConverter.fromConnectData(JsonSchemaConverter.java:90)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	... 16 more
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | Caused by: io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: RESTEASY003210: Could not find resource for full path: http://apicurio:8080/apis/ccompat/v7/subjects/dbserver1.public.timmyb32r_favourite_table-value/versions?normalize=false; error code: 0
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:297)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:367)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:544)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:532)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:490)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.registerAndGetId(CachedSchemaRegistryClient.java:257)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.register(CachedSchemaRegistryClient.java:366)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.register(CachedSchemaRegistryClient.java:337)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	at io.confluent.kafka.serializers.json.AbstractKafkaJsonSchemaSerializer.serializeImpl(AbstractKafkaJsonSchemaSerializer.java:106)
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 	... 18 more
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,130 INFO   ||  Stopping down connector   [io.debezium.connector.common.BaseSourceTask]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,523 INFO   Postgres|dbserver1|streaming  Connection gracefully closed   [io.debezium.jdbc.JdbcConnection]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,525 INFO   Postgres|dbserver1|streaming  Finished streaming   [io.debezium.pipeline.ChangeEventSourceCoordinator]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,525 INFO   Postgres|dbserver1|streaming  Connected metrics set to 'false'   [io.debezium.pipeline.ChangeEventSourceCoordinator]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,546 INFO   ||  Connection gracefully closed   [io.debezium.jdbc.JdbcConnection]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,549 INFO   ||  [Producer clientId=connector-producer-timmyb32r-schema-registry-pg-apicurio-with-confluent-serializer-0] Closing the Kafka producer with timeoutMillis = 30000 ms.   [org.apache.kafka.clients.producer.KafkaProducer]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,552 INFO   ||  Metrics scheduler closed   [org.apache.kafka.common.metrics.Metrics]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,553 INFO   ||  Closing reporter org.apache.kafka.common.metrics.JmxReporter   [org.apache.kafka.common.metrics.Metrics]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,553 INFO   ||  Metrics reporters closed   [org.apache.kafka.common.metrics.Metrics]
    debezium-schema-registry-pg-apicurio-with-confluent-serializer-connect-1    | 2023-03-26 20:28:53,553 INFO   ||  App info kafka.producer for connector-producer-timmyb32r-schema-registry-pg-apicurio-with-confluent-serializer-0 unregistered   [org.apache.kafka.common.utils.AppInfoParser]

    ```

## QUESTION

How to run this?)

## how built this docker-compose

It's modified copy of debezium-pg & docker-compose-mysql-apicurio.yaml (from debezium tutorials)
