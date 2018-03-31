Name:	        confluent	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Gojul's Confluent distribution (Confluent one packaged)

Group:		org.gojul.rpmbuildtools
License:	GPL
URL:		https://www.github.com//rpmbuildtools
Source0:	confluent.tgz

BuildRequires:	gojulrpmbuildtools

Requires:       java-1.8.0-openjdk-devel

%global __jar_repack %{nil}

%description
Confluent package suite contains all the packages required to make a standard
Confluent distribution for Apache Kafka to RHEL.

%prep
%setup -q -c

%package common
Summary: Confluent common files.

%description common
Confluent common components contains Confluent's distro common components..
The purpose here is to have a standard easy-to-use Confluent distribution.

%package camus
Summary: LinkedIn Camus
Requires: confluent-common

%description camus
LinkedIn Camus software.

%package kafka-serde-tools
Summary: Kafka Serde tools
Requires: confluent-common

%description kafka-serde-tools
Confluent Kafka Serde tools libraries.

%package kafka-libs
Summary: Kafka libs
Requires: confluent-common

%description kafka-libs
Confluent Kafka libraries.

%package kafka
Summary: Kafka server itself
Requires: confluent-kafka-libs
Requires: confluent-kafka-serde-tools

%description kafka
Confluent Kafka suite

%package kafka-mirror-maker
Summary: Kafka Mirror Maker
Requires: confluent-kafka-libs

%description kafka-mirror-maker
Kafka mirror maker

%package kafka-rest
Summary: Kafka REST connector
Requires: confluent-common

%description kafka-rest
Confluent Kafka REST connector.

%package kafka-connect-storage-common
Summary: Kafka connect storage common library
Requires: confluent-common
Requires: confluent-kafka-serde-tools

%description kafka-connect-storage-common
Confluent Kafka connect storage common libraries

%package kafka-connect-elasticsearch
Summary: Kafka connect ElasticSearch library
Requires: confluent-kafka-connect-storage-common

%description kafka-connect-elasticsearch
Confluent Kafka connect ElasticSearch library

%package kafka-connect-hdfs
Summary: Kafka connect HDFS library
Requires: confluent-kafka-connect-storage-common

%description kafka-connect-hdfs
Confluent Kafka connect HDFS library

%package kafka-connect-jdbc
Summary: Kafka connect JDBC library
Requires: confluent-kafka-connect-storage-common

%description kafka-connect-jdbc
Confluent Kafka connect JDBC library

%package kafka-connect-s3
Summary: Kafka connect S3 library
Requires: confluent-kafka-connect-storage-common

%description kafka-connect-s3
Confluent Kafka Connect for Amazon S3.

%package kafka-test-tools
Summary: Kafka test tools used to test a Kafka installation
Requires: confluent-kafka

%description kafka-test-tools
Kafka test tools to verify a Kafka installation

%package schema-registry
Summary: Kafka schema registry (Avro)
Requires: confluent-common

%description schema-registry
Kafka schema registry (Avro)

%package schema-registry-test-tools
Summary: Kafka schema registry test tools
Requires: confluent-schema-registry

%description schema-registry-test-tools
Kafka avro test tools to verify a Kafka installation

%package zookeeper
Summary: Kafka Zookeeper daemon
Requires: confluent-kafka-libs

%description zookeeper
Kafka Zookeeper

%pre zookeeper
getent passwd zookeeper > /dev/null || /usr/sbin/useradd zookeeper

if [ -f /etc/init.d/confluent-zookeeper ]
then
   /etc/init.d/confluent-zookeeper stop
fi

%post zookeeper
if [ "$1" == 0 ]
then
   chkconfig --add /etc/init.d/confluent-zookeeper || true
fi 

%preun zookeeper
if [ "$1" == 0 ]
then
   /etc/init.d/confluent-zookeeper stop || true
   chkconfig --del /etc/init.d/confluent-zookeeper || true
fi 

%install
rm -rf %{buildroot}/*
%cmake
make install DESTDIR=%{buildroot}

mkdir -p %{buildroot}%{_prefix}
cd %{buildroot}%{_prefix}
tar zxf %{_builddir}/%{name}-%{version}/confluent-distrib.tgz --strip-components 1 

rm -rf src

rm -rf README
rm -rf bin/windows
rm -rf bin/confluent

mv etc/* %{buildroot}/etc
rm -rf etc

for i in kafka zookeeper; do
   mkdir -p %{buildroot}/var/run/confluent-${i}
   mkdir -p %{buildroot}/var/log/confluent-${i}
done

%files common
%defattr(-,root,root,-)
%{_datadir}/confluent-common
%{_datadir}/java/confluent-common
%{_datadir}/java/rest-utils
%{_datadir}/rest-utils
%{_datadir}/doc/confluent-common
%{_datadir}/doc/rest-utils
%dir %{_sysconfdir}/confluent-common/
%dir %{_sysconfdir}/rest-utils/

%files camus
%defattr(-,root,root,-)
%{_bindir}/camus*
%{_datadir}/doc/camus
%{_datadir}/java/camus
%dir %{_sysconfdir}/camus
%config(noreplace) %{_sysconfdir}/camus/*

%files kafka-serde-tools
%defattr(-,root,root,-)
%{_datadir}/doc/kafka-serde-tools
%{_datadir}/java/kafka-serde-tools

%files kafka-libs
%defattr(-,root,root,-)
%{_bindir}/kafka-run-class
%{_datadir}/doc/kafka
%{_datadir}/java/kafka
%dir %{_sysconfdir}/kafka
%config(noreplace) %{_sysconfdir}/kafka/log4j.properties
%config(noreplace) %{_sysconfdir}/kafka/tools-log4j.properties

%files kafka
%defattr(-,root,root,-)
%{_bindir}/connect*
%{_bindir}/kafka-acls
%{_bindir}/kafka-broker-api-versions
%{_bindir}/kafka-configs
%{_bindir}/kafka-consumer-groups
%{_bindir}/kafka-consumer-offset-checker
%{_bindir}/kafka-delete-records
%{_bindir}/kafka-log-dirs
%{_bindir}/kafka-preferred-replica-election
%{_bindir}/kafka-reassign-partitions
%{_bindir}/kafka-replay-log-producer
%{_bindir}/kafka-replica-verification
%{_bindir}/kafka-server-*
%{_bindir}/kafka-streams-application-reset
%{_bindir}/kafka-topics
%{_bindir}/support-metrics-bundle
/var/run/confluent-kafka
%config(noreplace) %{_sysconfdir}/kafka/connect*
%config(noreplace) %{_sysconfdir}/kafka/server.properties

%files kafka-mirror-maker
%defattr(-,root,root,-)
%{_bindir}/kafka-mirror-maker

%files kafka-rest
%defattr(-,root,root,-)
%{_bindir}/kafka-rest-*
%{_datadir}/kafka-rest
%{_datadir}/doc/kafka-rest
%{_datadir}/java/kafka-rest
%dir %{_sysconfdir}/kafka-rest
%config(noreplace) %{_sysconfdir}/kafka-rest/*

%files kafka-connect-storage-common
%defattr(-,root,root,-)
%{_datadir}/doc/kafka-connect-storage-common
%{_datadir}/java/kafka-connect-storage-common
%dir %{_sysconfdir}/kafka-connect-storage-common

%files kafka-connect-elasticsearch
%defattr(-,root,root,-)
%{_datadir}/doc/kafka-connect-elasticsearch
%{_datadir}/java/kafka-connect-elasticsearch
%dir %{_sysconfdir}/kafka-connect-elasticsearch
%config(noreplace) %{_sysconfdir}/kafka-connect-elasticsearch/*

%files kafka-connect-hdfs
%defattr(-,root,root,-)
%{_datadir}/doc/kafka-connect-hdfs
%{_datadir}/java/kafka-connect-hdfs
%dir %{_sysconfdir}/kafka-connect-hdfs
%config(noreplace) %{_sysconfdir}/kafka-connect-hdfs/*

%files kafka-connect-jdbc
%defattr(-,root,root,-)
%{_datadir}/doc/kafka-connect-jdbc
%{_datadir}/java/kafka-connect-jdbc
%dir %{_sysconfdir}/kafka-connect-jdbc
%config(noreplace) %{_sysconfdir}/kafka-connect-jdbc/*

%files kafka-connect-s3
%defattr(-,root,root,-)
%{_datadir}/doc/kafka-connect-s3
%{_datadir}/java/kafka-connect-s3
%dir %{_sysconfdir}/kafka-connect-s3
%config(noreplace) %{_sysconfdir}/kafka-connect-s3/*

%files kafka-test-tools
%defattr(-,root,root,-)
%{_bindir}/kafka-console-*
%{_bindir}/kafka-*-perf-test
%{_bindir}/kafka-simple-consumer-shell
%{_bindir}/kafka-verifiable-*
%config(noreplace) %{_sysconfdir}/kafka/consumer.properties
%config(noreplace) %{_sysconfdir}/kafka/producer.properties

%files schema-registry
%defattr(-,root,root,-)
%{_bindir}/schema-registry-*
%{_datadir}/doc/schema-registry
%{_datadir}/java/schema-registry
%dir %{_sysconfdir}/schema-registry
%config(noreplace) %{_sysconfdir}/schema-registry/*

%files schema-registry-test-tools
%defattr(-,root,root,-)
%{_bindir}/kafka-avro-*

%files zookeeper
%defattr(-,root,root,-)
%{_bindir}/zookeeper*
/etc/init.d/confluent-zookeeper
%attr(-,zookeeper,zookeeper) /var/log/confluent-zookeeper
/var/run/confluent-zookeeper
%config(noreplace) %{_sysconfdir}/kafka/zookeeper.properties
