# Confluent.Kafka: producer and consumer configuration, topic partitions, offsets, headers and timestamps; no broker is used
load "pkg.ring"
pkgUse("kafkaconfig",[["Confluent.Kafka","2.6.1"]],[["Confluent.Kafka.dll",["Confluent.Kafka"]]])
pkgImport("kafkaconfig","Confluent.Kafka.dll","Confluent.Kafka")
dnImport("System")

oProducer = new ProducerConfig()
oProducer.BootstrapServers = "kafka1:9092,kafka2:9092"
oProducer.ClientId = "ring producer"
oProducer.LingerMs = 20
oProducer.EnableIdempotence = True
oProducer.MessageSendMaxRetries = 7
dnAssert("the servers",oProducer.BootstrapServers,"kafka1:9092,kafka2:9092")
dnAssert("the client id",oProducer.ClientId,"ring producer")
dnAssert("linger",oProducer.LingerMs,20)
dnAssert("idempotence",oProducer.EnableIdempotence,True)
dnAssert("retries",oProducer.MessageSendMaxRetries,7)
dnAssert("a setting that was not made",oProducer.BatchSize.isNull(),True)

oConsumer = new ConsumerConfig()
oConsumer.BootstrapServers = "kafka1:9092"
oConsumer.GroupId = "readers"
oConsumer.EnableAutoCommit = False
oConsumer.SessionTimeoutMs = 15000
dnAssert("the group",oConsumer.GroupId,"readers")
dnAssert("auto commit is off",oConsumer.EnableAutoCommit,False)
dnAssert("the session timeout",oConsumer.SessionTimeoutMs,15000)

# the configuration is a list of text pairs for librdkafka
nPairs = 0
for oPair in oConsumer.toList()
	nPairs++
next
dnAssert("a configuration has its pairs",nPairs >= 3,True)

# a topic partition and offsets
oPartition = new TopicPartition("orders",2)
dnAssert("the topic",oPartition.Topic,"orders")
dnAssert("the partition",oPartition.Partition.Value,2)
dnAssert("the text of a partition",oPartition.ToString(),"orders [[2]]")
oAtOffset = (new TopicPartitionOffset).@New([ :topic = "orders", :partition = 2, :offset = 100 ])
dnAssert("the offset",oAtOffset.Offset.Value,100)
dnAssert("the text with an offset",oAtOffset.ToString(),"orders [[2]] @100")
oSame = new TopicPartition("orders",2)
oOther = new TopicPartition("orders",3)
dnAssert("a partition equals itself",oPartition.Equals(oSame),True)
dnAssert("another partition is different",oPartition.Equals(oOther),False)

oBeginning = oAtOffset.Offset.getBeginning()
dnAssert("the beginning offset is special",oBeginning.IsSpecial,True)
dnAssert("the beginning offset text",oBeginning.ToString(),"Beginning [-2]")

# headers carry bytes
oHeaders = new Headers()
oHeaders.callMethod("Add",["trace","abc"])
dnAssert("a header was added",oHeaders.Count,1)

# a timestamp is milliseconds since 1970
oStamp = new Timestamp()
oDate = oStamp.UnixTimestampMsToDateTime(1700000000000)
dnAssert("the time of a number of milliseconds: year",oDate.Year,2023)
dnAssert("the time of a number of milliseconds: month",oDate.Month,11)
dnAssert("the number of milliseconds of a time",oStamp.DateTimeToUnixTimestampMs(oDate),1700000000000)

dnTestSummary()
