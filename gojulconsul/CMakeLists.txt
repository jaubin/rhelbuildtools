cmake_minimum_required(VERSION 2.8)

project(gojulconsul C)

install(DIRECTORY scripts/ DESTINATION /etc/init.d USE_SOURCE_PERMISSIONS)
install(DIRECTORY etc/ DESTINATION /etc USE_SOURCE_PERMISSIONS)
install(DIRECTORY doc DESTINATION /usr/share USE_SOURCE_PERMISSIONS)
install(DIRECTORY logrotate/ DESTINATION /etc/logrotate.d USE_SOURCE_PERMISSIONS)
