# ABOUT AKHQ:
https://akhq.io/docs/

# prerequisites
Kafka instance UP
Zookeeper instances UP
"Connect" instance UP

Login:
http://<IPv4-public-of-kafka-connect-instance>:8080/ui/login

From Kafka instance install Kafka and consume:
> curl -O https://packages.confluent.io/archive/7.6/confluent-7.6.0.zip
> confluent-7.6.0/bin/kafka-console-consumer --bootstrap-server localhost:9092 --topic articles --from-beginning

