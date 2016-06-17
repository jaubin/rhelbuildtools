cmake_minimum_required(VERSION 2.8)

project(gojulrpmbuildtools C)

install(DIRECTORY scripts/ DESTINATION /usr/bin USE_SOURCE_PERMISSIONS)
