cmake_minimum_required(VERSION 2.8)

project(gojulgatling C)

install(DIRECTORY scripts/ DESTINATION /usr/bin USE_SOURCE_PERMISSIONS)
install(DIRECTORY conf/ DESTINATION /etc/gatling USE_SOURCE_PERMISSIONS)
