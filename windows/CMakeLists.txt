cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "oronbox_network")
project(${PROJECT_NAME} LANGUAGES C CXX)

include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/OronBoxNetworkPrebuilt.cmake")

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
  message(FATAL_ERROR "OronBox Network supports 64-bit Windows builds only")
endif()

set(PREBUILT_DIR
  "${CMAKE_CURRENT_BINARY_DIR}/prebuilt/${ORONBOX_NETWORK_VERSION}")
oronbox_network_fetch("oronbox-network-windows-x86_64.zip" "${PREBUILT_DIR}")

add_library(oronbox_network SHARED IMPORTED GLOBAL)
set_target_properties(oronbox_network PROPERTIES
  IMPORTED_IMPLIB "${PREBUILT_DIR}/lib/oronbox_network.dll.lib"
  IMPORTED_LOCATION "${PREBUILT_DIR}/lib/oronbox_network.dll")

set(oronbox_network_bundled_libraries
  "${PREBUILT_DIR}/lib/oronbox_network.dll"
  PARENT_SCOPE)
