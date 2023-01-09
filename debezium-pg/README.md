# default debezium postgres->kafka CDC

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

4) read message from kafka (For some reason, kcat don't work as consumer with debezium-kafka-2.0)
    ```
    docker ps | grep kafka | awk '{print $1}' | xargs -I {} docker exec {} ./bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic dbserver1.public.timmyb32r_favourite_table --from-beginning --property print.key=true --max-messages 1
        {"schema":{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"}],"optional":false,"name":"dbserver1.public.timmyb32r_favourite_table.Key"},"payload":{"id":1}}	{"schema":{"type":"struct","fields":[{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"},{"type":"string","optional":true,"field":"val"}],"optional":true,"name":"dbserver1.public.timmyb32r_favourite_table.Value","field":"before"},{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"},{"type":"string","optional":true,"field":"val"}],"optional":true,"name":"dbserver1.public.timmyb32r_favourite_table.Value","field":"after"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"version"},{"type":"string","optional":false,"field":"connector"},{"type":"string","optional":false,"field":"name"},{"type":"int64","optional":false,"field":"ts_ms"},{"type":"string","optional":true,"name":"io.debezium.data.Enum","version":1,"parameters":{"allowed":"true,last,false,incremental"},"default":"false","field":"snapshot"},{"type":"string","optional":false,"field":"db"},{"type":"string","optional":true,"field":"sequence"},{"type":"string","optional":false,"field":"schema"},{"type":"string","optional":false,"field":"table"},{"type":"int64","optional":true,"field":"txId"},{"type":"int64","optional":true,"field":"lsn"},{"type":"int64","optional":true,"field":"xmin"}],"optional":false,"name":"io.debezium.connector.postgresql.Source","field":"source"},{"type":"string","optional":false,"field":"op"},{"type":"int64","optional":true,"field":"ts_ms"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"id"},{"type":"int64","optional":false,"field":"total_order"},{"type":"int64","optional":false,"field":"data_collection_order"}],"optional":true,"name":"event.block","version":1,"field":"transaction"}],"optional":false,"name":"dbserver1.public.timmyb32r_favourite_table.Envelope","version":1},"payload":{"before":null,"after":{"id":1,"val":"blablabla"},"source":{"version":"2.0.1.Final","connector":"postgresql","name":"dbserver1","ts_ms":1673295233134,"snapshot":"false","db":"postgres","sequence":"[\"33976960\",\"33976960\"]","schema":"public","table":"timmyb32r_favourite_table","txId":754,"lsn":33976960,"xmin":null},"op":"c","ts_ms":1673295233506,"transaction":null}}
    ```
    As we see - everything is here!


## notes

- If you want to use debezium lower than 2.0 - you should change topic.prefix on database.server.name back in config
- For some reason, kcat don't work as consumer with debezium-kafka-2.0

## how built this docker-compose

It's pure copy of https://github.com/debezium/debezium-examples/blob/main/tutorial/docker-compose-postgres.yaml
