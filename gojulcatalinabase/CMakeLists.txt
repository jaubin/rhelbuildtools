cmake_minimum_required(VERSION 2.8)

project(gojultomcat C)

install(DIRECTORY tomcat-base/ DESTINATION /home/gojultomcat USE_SOURCE_PERMISSIONS)
install(PROGRAMS gojultomcat DESTINATION /etc/init.d)
