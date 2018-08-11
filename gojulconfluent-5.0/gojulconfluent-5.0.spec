Name:	        confluent-5.0	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Gojul's Confluent distribution (Confluent one packaged) - UNOFFICIAL

Group:		org.gojul.rpmbuildtools
License:	GPL
URL:		https://www.github.com//rpmbuildtools
Source0:	confluent.tgz

BuildRequires:	gojulrpmbuildtools

%global __jar_repack %{nil}
%global __versrel %{version}-%{release}

%description
Confluent package suite contains all the packages required to make a standard
Confluent distribution for Apache Kafka to RHEL.

%prep
%setup -q -c

%package common
Summary: Confluent common files.

Requires:       bash
Requires:       coreutils
Requires:       gawk
Requires:       grep
Requires:       java-1.8.0-openjdk-devel
Requires:       procps
Requires:       shadow-utils
Requires:       systemd

Conflicts:      confluent-4.0-common
Conflicts:      confluent-4.1-common

%description common
Confluent common components contains Confluent's distro common components..
The purpose here is to have a standard easy-to-use Confluent distribution.

#-------------------------- KAFKA --------------------------------------

%package kafka-serde-tools
Summary: Kafka Serde tools
Requires: confluent-5.0-common = %{__versrel}

%description kafka-serde-tools
Confluent Kafka Serde tools libraries.



%package kafka-libs
Summary: Kafka libs
Requires: confluent-5.0-common = %{__versrel}

%description kafka-libs
Confluent Kafka libraries.



%package kafka
Summary: Kafka server itself
Requires: confluent-5.0-kafka-libs = %{__versrel}
Requires: confluent-5.0-kafka-serde-tools = %{__versrel}

%description kafka
Confluent Kafka suite

%pre kafka
getent passwd cp-kafka > /dev/null || /usr/sbin/useradd cp-kafka
getent passwd cp-kafka-connect > /dev/null || /usr/sbin/useradd cp-kafka-connect
getent group confluent > /dev/null || /usr/sbin/groupadd confluent

serviceStatus=$(/bin/systemctl is-active confluent-kafka)
if [ "$serviceStatus" == "active" ]
then
   /bin/systemctl stop confluent-kafka || true
fi

%post kafka
/bin/systemctl daemon-reload
/bin/systemctl enable confluent-kafka || true

%preun kafka
if [ "$1" == 0 ]
then
   /bin/systemctl stop confluent-kafka || true
   /bin/systemctl disable confluent-kafka || true
fi 

%postun kafka
/bin/systemctl daemon-reload

%package kafka-mirror-maker
Summary: Kafka Mirror Maker
Requires: confluent-5.0-kafka-libs = %{__versrel}

%description kafka-mirror-maker
Kafka mirror maker


%package kafka-test-tools
Summary: Kafka test tools used to test a Kafka installation
Requires: confluent-5.0-kafka-libs = %{__versrel}

%description kafka-test-tools
Kafka test tools to verify a Kafka installation


#--------------------------------- KSQL ----------------------------------------

%package ksql
Summary: Kafka KSQL tools
Requires: confluent-5.0-common = %{__versrel}

%description ksql
KSQL utilities for Kafka.

%pre ksql
getent passwd cp-ksql > /dev/null || /usr/sbin/useradd cp-ksql
getent group confluent > /dev/null || /usr/sbin/groupadd confluent

serviceStatus=$(/bin/systemctl is-active confluent-ksql)
if [ "$serviceStatus" == "active" ]
then
   /bin/systemctl stop confluent-ksql || true
fi

%post ksql
/bin/systemctl daemon-reload
/bin/systemctl enable confluent-ksql || true

%preun ksql
if [ "$1" == 0 ]
then
   /bin/systemctl stop confluent-ksql || true
   /bin/systemctl disable confluent-ksql || true
fi 

%postun ksql
/bin/systemctl daemon-reload



#--------------------------------- KAFKA REST -------------------------------------

%package kafka-rest
Summary: Kafka REST connector
Requires: confluent-5.0-common = %{__versrel}

%description kafka-rest
Confluent Kafka REST connector.

%pre kafka-rest
getent passwd cp-kafka-rest > /dev/null || /usr/sbin/useradd cp-kafka-rest
getent group confluent > /dev/null || /usr/sbin/groupadd confluent

serviceStatus=$(/bin/systemctl is-active confluent-kafka-rest)
if [ "$serviceStatus" == "active" ]
then
   /bin/systemctl stop confluent-kafka-rest || true
fi

%post kafka-rest
/bin/systemctl daemon-reload
/bin/systemctl enable confluent-kafka-rest || true

%preun kafka-rest
if [ "$1" == 0 ]
then
   /bin/systemctl stop confluent-kafka-rest || true
   /bin/systemctl disable confluent-kafka-rest || true
fi 

%postun kafka-rest
/bin/systemctl daemon-reload



#-------------------------------- KAFKA CONNECT ------------------------------------

%package kafka-connect-storage-common
Summary: Kafka connect storage common library
Requires: confluent-5.0-common = %{__versrel}
Requires: confluent-5.0-kafka-serde-tools = %{__versrel}

%description kafka-connect-storage-common
Confluent Kafka connect storage common libraries



%package kafka-connect-elasticsearch
Summary: Kafka connect ElasticSearch library
Requires: confluent-5.0-kafka-connect-storage-common = %{__versrel}

%description kafka-connect-elasticsearch
Confluent Kafka connect ElasticSearch library



%package kafka-connect-hdfs
Summary: Kafka connect HDFS library
Requires: confluent-5.0-kafka-connect-storage-common = %{__versrel}

%description kafka-connect-hdfs
Confluent Kafka connect HDFS library



%package kafka-connect-jdbc
Summary: Kafka connect JDBC library
Requires: confluent-5.0-kafka-connect-storage-common = %{__versrel}

%description kafka-connect-jdbc
Confluent Kafka connect JDBC library



%package kafka-connect-s3
Summary: Kafka connect S3 library
Requires: confluent-5.0-kafka-connect-storage-common = %{__versrel}

%description kafka-connect-s3
Confluent Kafka Connect for Amazon S3.

#---------------------------------- KAFKA SCHEMA REGISTRY (AVRO) -----------------------------------

%package schema-registry
Summary: Kafka schema registry (Avro)
Requires: confluent-5.0-common = %{__versrel}

%description schema-registry
Kafka schema registry (Avro)

%pre schema-registry
getent passwd cp-schema-registry > /dev/null || /usr/sbin/useradd cp-schema-registry
getent group confluent > /dev/null || /usr/sbin/groupadd confluent

serviceStatus=$(/bin/systemctl is-active confluent-schema-registry)
if [ "$serviceStatus" == "active" ]
then
   /bin/systemctl stop confluent-schema-registry || true
fi

%post schema-registry
/bin/systemctl daemon-reload
/bin/systemctl enable confluent-schema-registry || true

%preun schema-registry
if [ "$1" == 0 ]
then
   /bin/systemctl stop confluent-schema-registry || true
   /bin/systemctl disable confluent-schema-registry || true
fi 

%postun schema-registry
/bin/systemctl daemon-reload

%package schema-registry-test-tools
Summary: Kafka schema registry test tools
Requires: confluent-5.0-schema-registry = %{__versrel}

%description schema-registry-test-tools
Kafka avro test tools to verify a Kafka installation

#----------------------------------- ZOOKEEPER ---------------------------------------------

%package zookeeper
Summary: Kafka Zookeeper daemon
Requires: confluent-5.0-kafka-libs = %{__versrel}

%description zookeeper
Kafka Zookeeper

%pre zookeeper
getent passwd cp-kafka > /dev/null || /usr/sbin/useradd cp-kafka
getent group confluent > /dev/null || /usr/sbin/groupadd confluent

serviceStatus=$(/bin/systemctl is-active confluent-zookeeper)
if [ "$serviceStatus" == "active" ]
then
   /bin/systemctl stop confluent-zookeeper || true
fi

%post zookeeper
/bin/systemctl daemon-reload
/bin/systemctl enable confluent-zookeeper || true

%preun zookeeper
if [ "$1" == 0 ]
then
   /bin/systemctl stop confluent-zookeeper || true
   /bin/systemctl disable confluent-zookeeper || true
fi 

%postun zookeeper
/bin/systemctl daemon-reload


#--------------------------------------- INSTALL SECTION ---------------------------------------

%install

mkdir -p %{buildroot}%{_prefix}
cd %{buildroot}%{_prefix}
tar zxf %{_builddir}/%{name}-%{version}/confluent-distrib.tgz --strip-components 1 

rm -rf src

rm -rf README
rm -rf bin/windows
rm -rf bin/confluent

mv etc %{buildroot}
rm -rf etc

for i in kafka kafka-rest ksql schema-registry zookeeper; do
   mkdir -p %{buildroot}/var/log/confluent/${i}
done

#-------------------------- FILES ----------------------------------------

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

%files kafka-serde-tools
%defattr(-,root,root,-)
%{_datadir}/doc/kafka-serde-tools
%{_datadir}/java/kafka-serde-tools

%files kafka-libs
%defattr(-,root,root,-)
%{_bindir}/kafka-run-class*
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
%{_bindir}/kafka-delete-records
%{_bindir}/kafka-delegation-tokens
%{_bindir}/kafka-dump-log
%{_bindir}/kafka-log-dirs
%{_bindir}/kafka-preferred-replica-election
%{_bindir}/kafka-reassign-partitions
%{_bindir}/kafka-replica-verification
%{_bindir}/kafka-server-*
%{_bindir}/kafka-streams-application-reset
%{_bindir}/kafka-topics
%{_bindir}/support-metrics-bundle
/usr/lib/systemd/system/confluent-kafka-connect.service
/usr/lib/systemd/system/confluent-kafka.service
%attr(-,cp-kafka,confluent) /var/log/confluent/kafka
%config(noreplace) %{_sysconfdir}/kafka/connect*
%config(noreplace) %{_sysconfdir}/kafka/server.properties
%config(noreplace) %{_sysconfdir}/kafka/trogdor.conf

%files kafka-mirror-maker
%defattr(-,root,root,-)
%{_bindir}/kafka-mirror-maker

%files ksql
%defattr(-,root,root,-)
%{_bindir}/ksql*
%{_datadir}/doc/ksql
%{_datadir}/java/ksql
/usr/lib/systemd/system/confluent-ksql.service
%attr(-,cp-ksql,confluent) /var/log/confluent/ksql
%dir %{_sysconfdir}/ksql
%config(noreplace) %{_sysconfdir}/ksql/*

%files kafka-rest
%defattr(-,root,root,-)
%{_bindir}/kafka-rest-*
%{_datadir}/doc/kafka-rest
%{_datadir}/java/kafka-rest
/usr/lib/systemd/system/confluent-kafka-rest.service
%attr(-,cp-kafka-rest,confluent) /var/log/confluent/kafka-rest
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
%{_bindir}/kafka-verifiable-*
%config(noreplace) %{_sysconfdir}/kafka/consumer.properties
%config(noreplace) %{_sysconfdir}/kafka/producer.properties

%files schema-registry
%defattr(-,root,root,-)
%{_bindir}/schema-registry-*
%{_datadir}/doc/schema-registry
%{_datadir}/java/schema-registry
/usr/lib/systemd/system/confluent-schema-registry.service
%attr(-,cp-schema-registry,confluent) /var/log/confluent/schema-registry
%dir %{_sysconfdir}/schema-registry
%config(noreplace) %{_sysconfdir}/schema-registry/*

%files schema-registry-test-tools
%defattr(-,root,root,-)
%{_bindir}/kafka-avro-*

%files zookeeper
%defattr(-,root,root,-)
%{_bindir}/zookeeper*
/usr/lib/systemd/system/confluent-zookeeper.service
%attr(-,cp-kafka,confluent) /var/log/confluent/zookeeper
%config(noreplace) %{_sysconfdir}/kafka/zookeeper.properties
