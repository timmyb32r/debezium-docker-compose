# debezium 'on premise pg (on ip v6 with workaround)' -> 'on premise kafka' SNAPSHOT (tested on yandex.cloud: managed pg & managed kafka)

## demo

0) prepare cert
    ```sh
    mkdir ./cert
    wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" --output-document ./cert/CA.pem
    openssl x509 -outform der -in ./cert/CA.pem -out ./cert/CA.der
    keytool -importcert -noprompt -alias ca -file ./cert/CA.der -keystore ./cert/CA.p12 -storepass STOREPASSW0RD
    ```

1) prepare env variables
    ```sh
    export \
        KAFKA_BOOTSTRAP_SERVERS=my_kafka_host:my_kafka_port \
        KAFKA_USER=my_kafka_user \
        KAFKA_PASS=my_kafka_pass \
        PG_IPV6=my_pg_ipv6 \
        PG_DATABASE=my_pg_db \
        PG_SCHEMA=public \
        PG_TABLE_NAME=timmyb32r_favourite_table \
        PG_USER=my_pg_user \
        PG_PASS=my_pg_pass
    ```

2) uprise docker-compose
    ```sh
    docker-compose up
    ```

3) workaround for ip v6 - make port forvarding from ipv6 to localhost
    ```sh
    socat tcp4-listen:6432,fork tcp6:[${PG_IPV6}]:6432
    ```
    
    we can check if port forwarding works - this way:
    ```sh
    export PGPASSWORD=${PG_PASS} && psql -h 127.0.0.1 -p 6432 -U ${PG_USER} -d ${PG_DATABASE}
    ```

4) prepare & register connector
    ```sh
    # prepare env variables - if it's another console
    cat ./register-pg-onprem.json.template | \
        sed "s/KAFKA_BOOTSTRAP_SERVERS/$KAFKA_BOOTSTRAP_SERVERS/g" | \
        sed "s/KAFKA_USER/$KAFKA_USER/g" | \
        sed "s/KAFKA_PASS/$KAFKA_PASS/g" | \
        sed "s/PG_HOSTNAME/$PG_HOSTNAME/g" | \
        sed "s/PG_DATABASE/$PG_DATABASE/g" | \
        sed "s/PG_USER/$PG_USER/g" | \
        sed "s/PG_PASS/$PG_PASS/g" \
        >./register-pg-onprem.json

    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-pg-onprem.json
    ```

5) create table & insert row
    ```sh
    export PGPASSWORD=${PG_PASS} && psql -h 127.0.0.1 -p 6432 -U ${PG_USER} -d ${PG_DATABASE}
    CREATE TABLE public.timmyb32r_favourite_table(id INT PRIMARY KEY, val text);
    INSERT INTO public.timmyb32r_favourite_table(id, val) VALUES (1, 'blablabla');
    \q
    ```

6) check if topic created
    ```sh
    kcat -L \
        -b $KAFKA_BOOTSTRAP_SERVERS \
        -t dbserver1.${PG_SCHEMA}.${PG_TABLE_NAME} \
        -X security.protocol=SASL_SSL \
        -X sasl.mechanisms=SCRAM-SHA-512 \
        -X sasl.username=$KAFKA_USER \
        -X sasl.password=$KAFKA_PASS \
        -X ssl.ca.location=./cert/CA.pem
        
    Metadata for dbserver1.public.timmyb32r_favourite_table (from broker 1: sasl_ssl://rc1a-6lruivh4q51snbj8.mdb.cloud.yandex.net:9091/1):
     3 brokers:
      broker 2 at rc1b-rn9jgaoelc2us8hq.mdb.cloud.yandex.net:9091
      broker 3 at rc1c-ltsatg1tplqj06f5.mdb.cloud.yandex.net:9091 (controller)
      broker 1 at rc1a-6lruivh4q51snbj8.mdb.cloud.yandex.net:9091
     1 topics:
      topic "dbserver1.public.timmyb32r_favourite_table" with 1 partitions:
        partition 0, leader 2, replicas: 2,1,3, isrs: 2,1,3
    ```

7) read message from kafka
    ```sh
    kcat -C \
        -b $KAFKA_BOOTSTRAP_SERVERS \
        -t dbserver1.${PG_SCHEMA}.${PG_TABLE_NAME} \
        -X security.protocol=SASL_SSL \
        -X sasl.mechanisms=SCRAM-SHA-512 \
        -X sasl.username=$KAFKA_USER \
        -X sasl.password=$KAFKA_PASS \
        -X ssl.ca.location=./cert/CA.pem
    ```

## notes

- Note that in register-pg-onprem.json.template: "database.hostname": "host.docker.internal". It's for go to localhost port forwarding

## how built this docker-compose

It's modified copy of 'debezium-onprem-mysql' example
