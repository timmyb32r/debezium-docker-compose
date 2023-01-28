# debezium 'on premise mysql' -> 'on premise kafka' CDC (tested on yandex.cloud: managed mysql & managed kafka)

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
        MYSQL_HOSTNAME=my_mysql_host \
        MYSQL_DATABASE=my_mysql_db \
        MYSQL_USER=my_mysql_user \
        MYSQL_PASS=my_mysql_pass
    ```

2) uprise docker-compose
    ```sh
    docker-compose up
    ```

3) prepare & register connector
    ```sh
    # prepare env variables - if it's another console
    cat ./register-mysql-onprem.json.template | \
        sed "s/KAFKA_BOOTSTRAP_SERVERS/$KAFKA_BOOTSTRAP_SERVERS/g" | \
        sed "s/KAFKA_USER/$KAFKA_USER/g" | \
        sed "s/KAFKA_PASS/$KAFKA_PASS/g" | \
        sed "s/MYSQL_HOSTNAME/$MYSQL_HOSTNAME/g" | \
        sed "s/MYSQL_DATABASE/$MYSQL_DATABASE/g" | \
        sed "s/MYSQL_USER/$MYSQL_USER/g" | \
        sed "s/MYSQL_PASS/$MYSQL_PASS/g" \
        >./register-mysql-onprem.json

    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-mysql-onprem.json
    ```

4) create table & insert row
    ```sh
    mysql -u $MYSQL_USER -p$MYSQL_PASS -h $MYSQL_HOSTNAME $MYSQL_DATABASE
    CREATE TABLE timmyb32r_favourite_table (id INT NOT NULL, val VARCHAR(15) NOT NULL, PRIMARY KEY (id));
    INSERT INTO timmyb32r_favourite_table(id, val) VALUES (1, 'blablabla');
    \q
    ```

5) check if topic created
    ```sh
    kcat -L \
         -b $KAFKA_BOOTSTRAP_SERVERS \
         -t dbserver1.$MYSQL_DATABASE.timmyb32r_favourite_table \
         -X security.protocol=SASL_SSL \
         -X sasl.mechanisms=SCRAM-SHA-512 \
         -X sasl.username=$KAFKA_USER \
         -X sasl.password=$KAFKA_PASS \
         -X ssl.ca.location=./cert/CA.pem
      topic "dbserver1.$MYSQL_DATABASE.timmyb32r_favourite_table" with 1 partitions:
        partition 0, leader 2, replicas: 2,1,3, isrs: 2,1,3
    ```

5) read message from kafka
    ```sh
    kcat -C \
         -b $KAFKA_BOOTSTRAP_SERVERS \
         -t dbserver1.$MYSQL_DATABASE.timmyb32r_favourite_table \
         -X security.protocol=SASL_SSL \
         -X sasl.mechanisms=SCRAM-SHA-512 \
         -X sasl.username=$KAFKA_USER \
         -X sasl.password=$KAFKA_PASS \
         -X ssl.ca.location=./cert/CA.pem -Z -K:
    ```
