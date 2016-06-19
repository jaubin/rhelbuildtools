# rhelbuildtools

rhelbuildtools contains various scripts used in order to automatically build RPM packages and so on. 

These tools are designed to be used with continuous integration systems like Jenkins. They're to be used with Git. Note that we do not use mock in most of these tools, meaning that they should NOT be used in order to build C code. This is because of performance reasons as mock is extremely expensive to run on a CI server.

The main target of these tools is to make it easy to create packaged webapps with all the stuff needed in order to deploy them easily on a Tomcat server. The Tomcat distribution itself is provided with this tools.

This project also embeds a Tomcat distribution, in order to ease your work when packaging and deploying Tomcat apps.

## Available scripts :

* build_packages.sh : looks for all the RPM spec files which are exactly one level under the current directory, and builds the RPM.
* build_war_rpm.sh : create a RPM for each of the WAR packages located under the current Maven project. A Tomcat distribution with configuration is included in this project so that the whole thing can be easily installed on any RHEL server.
* publish_rpm.sh : publish a RPM package to the specified Maven repo. This one must be able to behave as a RPM repo. Nexus notably does.

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
