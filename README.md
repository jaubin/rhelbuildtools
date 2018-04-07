# rhelbuildtools

rhelbuildtools contains various scripts used in order to automatically build RPM packages and so on. 

These tools are designed to be used with continuous integration systems like Jenkins. They're to be used with Git. Note that we do not use mock in most of these tools, meaning that they should NOT be used in order to build C code. This is because of performance reasons as mock is extremely expensive to run on a CI server.

The main target of these tools is to make it easy to create packaged webapps with all the stuff needed in order to deploy them easily on a Tomcat server. The Tomcat distribution itself is provided with this tools.

This project also embeds a Tomcat distribution, in order to ease your work when packaging and deploying Tomcat apps.

## Available scripts :

* build_packages.sh : looks for all the RPM spec files which are exactly one level under the current directory, and builds the RPM.
* build_war_rpm.sh : create a RPM for each of the WAR packages located under the current Maven project. A Tomcat distribution with configuration is included in this project so that the whole thing can be easily installed on any RHEL server.
* publish_rpm.sh : publish a RPM package to the specified Maven repo. This one must be able to behave as a RPM repo. Nexus notably does.
* create_release.sh : build the RPM packages, tag the SCM, increment the project versions and pushes the built RPM packages to the local maven repo.

Each of these scripts includes a more detailed help. You can display it with the "-h" argument.

## Version management for RPMs

Version management must be done in file package-info.properties which is located at the root of each project. Each of these files has an entry named project.version with a version specified under the form x.y.z where :

* x is the project major version
* y is the project minor version
* z is a value incremented for each release

Actually you may have more version digits, but these are the minimum required ones.

The important thing is that the x.y couple must be unique for a given development branch, otherwise when tagging you will have conflicts which may result into unpredictable situations. In other words if your master has a version 2.0 and you create a branch for it, then you should change the version of your master to 2.1 or 3.0 or whatever you want, so that it does not match the version digits of the branch.

## Dependency on Maven

These tools need Apache Maven to work correctly. Here's how to install it on RHEL 6.x :

```bash
sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo

sudo yum install apache-maven
```
   
## Bootstrapping

Once you've clone the repo and are inside its root directory, run the following commands :

```bash
./gojulrpmbuildtools/scripts/build_package.sh gojulrpmbuildtools/gojulrpmbuildtools.spec
sudo rpm -i target/results/*.rpm
```

Then you can happily rebuild all the packages of the repo using command :

```bash
build_packages.sh
```

## Available software

Apart from the available build tools, the following software have been packages :
* Tomcat (directories gojultomcat and gojulcatalinabase) : required because RHEL's official Tomcat is really weirdly packaged.
* Kafka (directory gojulconfluent) : RHEL RPM packages for Confluent/Kafka. This way, Kafka is cleanly package because as of now, Confluent does not provide clean packages but instead a tar.gz distro. You must first download an official Confluent distro prior to packaging (check instructions in the README file from the gojulconfluent/ subdirectory).
* Consul (directory gojulconsul) : RHEL RPM packages for Consul service registry.
