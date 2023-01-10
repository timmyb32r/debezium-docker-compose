# default debezium mysql->kafka CDC

## demo

0) run docker-compose
    ```sh
    export DEBEZIUM_VERSION=2.0 && docker-compose up
    ```

1) register & run debezium kafka-connector
    ```sh
    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-mysql.json
    ```

2) create table & insert one record
    ```
    docker-compose -f docker-compose.yaml exec mysql bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD inventory'
    CREATE TABLE timmyb32r_favourite_table (id INT NOT NULL, val VARCHAR(15) NOT NULL, PRIMARY KEY (id));
    INSERT INTO timmyb32r_favourite_table(id, val) VALUES (1, 'blablabla');
    \q
    ```
3) check if topic created
    ```sh
    > kcat -b localhost:9092 -L
      ...
      topic "dbserver1.inventory.timmyb32r_favourite_table" with 1 partitions:
          partition 0, leader 1, replicas: 1, isrs: 1
    ```

4) read message from kafka (For some reason, kcat don't work as consumer with debezium-kafka-2.0)
    ```
    docker ps | grep kafka | awk '{print $1}' | xargs -I {} docker exec {} ./bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic dbserver1.inventory.timmyb32r_favourite_table --from-beginning --property print.key=true --max-messages 1
        {"schema":{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"}],"optional":false,"name":"dbserver1.inventory.timmyb32r_favourite_table.Key"},"payload":{"id":1}}	{"schema":{"type":"struct","fields":[{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"},{"type":"string","optional":false,"field":"val"}],"optional":true,"name":"dbserver1.inventory.timmyb32r_favourite_table.Value","field":"before"},{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"},{"type":"string","optional":false,"field":"val"}],"optional":true,"name":"dbserver1.inventory.timmyb32r_favourite_table.Value","field":"after"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"version"},{"type":"string","optional":false,"field":"connector"},{"type":"string","optional":false,"field":"name"},{"type":"int64","optional":false,"field":"ts_ms"},{"type":"string","optional":true,"name":"io.debezium.data.Enum","version":1,"parameters":{"allowed":"true,last,false,incremental"},"default":"false","field":"snapshot"},{"type":"string","optional":false,"field":"db"},{"type":"string","optional":true,"field":"sequence"},{"type":"string","optional":true,"field":"table"},{"type":"int64","optional":false,"field":"server_id"},{"type":"string","optional":true,"field":"gtid"},{"type":"string","optional":false,"field":"file"},{"type":"int64","optional":false,"field":"pos"},{"type":"int32","optional":false,"field":"row"},{"type":"int64","optional":true,"field":"thread"},{"type":"string","optional":true,"field":"query"}],"optional":false,"name":"io.debezium.connector.mysql.Source","field":"source"},{"type":"string","optional":false,"field":"op"},{"type":"int64","optional":true,"field":"ts_ms"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"id"},{"type":"int64","optional":false,"field":"total_order"},{"type":"int64","optional":false,"field":"data_collection_order"}],"optional":true,"name":"event.block","version":1,"field":"transaction"}],"optional":false,"name":"dbserver1.inventory.timmyb32r_favourite_table.Envelope","version":1},"payload":{"before":null,"after":{"id":1,"val":"blablabla"},"source":{"version":"2.0.1.Final","connector":"mysql","name":"dbserver1","ts_ms":1673347731000,"snapshot":"false","db":"inventory","sequence":null,"table":"timmyb32r_favourite_table","server_id":223344,"gtid":null,"file":"mysql-bin.000003","pos":677,"row":0,"thread":12,"query":null},"op":"c","ts_ms":1673347731080,"transaction":null}}
    ```
    As we see - everything is here!


## notes

- If you want to use debezium lower than 2.0 - you should change topic.prefix on database.server.name back in config
- For some reason, kcat don't work as consumer with debezium-kafka-2.0

## how built this docker-compose

It's pure copy of https://github.com/debezium/debezium-examples/blob/main/tutorial/docker-compose-mysql.yaml
