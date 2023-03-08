# debezium postgres->kafka CDC without schema in every message

## demo

0) run docker-compose
    ```sh
    export DEBEZIUM_VERSION=2.0 && docker-compose up
    ```

1) register & run debezium kafka-connector
    ```sh
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-without-schema.json
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
        {"id":1}	{"before":null,"after":{"id":1,"val":"blablabla"},"source":{"version":"2.0.1.Final","connector":"postgresql","name":"dbserver1","ts_ms":1678289937327,"snapshot":"false","db":"postgres","sequence":"[\"33976960\",\"33976960\"]","schema":"public","table":"timmyb32r_favourite_table","txId":754,"lsn":33976960,"xmin":null},"op":"c","ts_ms":1678289937562,"transaction":null}
    ```
    As we see - everything is here!


## notes

- If you want to use debezium lower than 2.0 - you should change topic.prefix on database.server.name back in config
- For some reason, kcat don't work as consumer with debezium-kafka-2.0

## how built this docker-compose

It's copy of debezium-pg with modification of register-postgres-without-schema.json - added:
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false"
