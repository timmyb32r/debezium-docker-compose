# debezium postgres->kafka CDC with topic routing - which merges any table events into one topic

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
    CREATE TABLE public.timmyb32r_favourite_table0(id INT PRIMARY KEY, val text);
    CREATE TABLE public.timmyb32r_favourite_table1(id INT PRIMARY KEY, val text);
    INSERT INTO public.timmyb32r_favourite_table0(id, val) VALUES (1, 'aaa');
    INSERT INTO public.timmyb32r_favourite_table1(id, val) VALUES (1, 'aaa');
    \q
    ```
3) check if topic created
    ```sh
    > kcat -b localhost:9092 -L
      ...
      topic "timmyb32r_server.timmyb32r_schema.timmyb32r_topic_name" with 1 partitions:
          partition 0, leader 1, replicas: 1, isrs: 1
    ```

4) read message from kafka (For some reason, kcat don't work as consumer with debezium-kafka-2.0)
    ```
    docker ps | grep kafka | awk '{print $1}' | xargs -I {} docker exec {} ./bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic 
    ```

## how built this docker-compose

It's modified copy of 'debezium-pg' example
