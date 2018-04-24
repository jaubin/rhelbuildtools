cmake_minimum_required(VERSION 2.8)

project(gojulconfluent C)

install(DIRECTORY scripts/ DESTINATION /etc/init.d USE_SOURCE_PERMISSIONS)
