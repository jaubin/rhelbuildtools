cmake_minimum_required(VERSION 2.8)

project(gojulrpmbuildtools C)

install(DIRECTORY scripts/ DESTINATION /usr/bin USE_SOURCE_PERMISSIONS)
install(DIRECTORY rpmmacros/ DESTINATION /etc/rpm USE_SOURCE_PERMISSIONS)
install(DIRECTORY resources/ DESTINATION /usr/share/gojulrpmbuildtools USE_SOURCE_PERMISSIONS)
install(DIRECTORY config/ DESTINATION /etc/gojulrpmbuildtools USE_SOURCE_PERMISSIONS)
