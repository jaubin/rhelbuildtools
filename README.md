# rhelbuildtools

rhelbuildtools contains various scripts used in order to automatically build RPM packages and so on. 

These tools are designed to be used with continuous integration systems like Jenkins. They're to be used with Git. Note that we do not use mock in most of these tools, meaning that they should NOT be used in order to build C code. This is because of performance reasons as mock is extremely expensive to run on a CI server.

The main target of these tools is to make it easy to create packaged webapps with all the stuff needed in order to deploy them easily on a Tomcat server. The Tomcat distribution itself is provided with this tools.

## Dependency on Maven

These tools need Apache Maven to work correctly. Here's how to install it on RHEL 6.x :

   sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo

   sudo yum install apache-maven
