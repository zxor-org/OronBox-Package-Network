cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "oronbox_network")
project(${PROJECT_NAME} LANGUAGES C CXX)

include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/OronBoxNetworkPrebuilt.cmake")

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
  set(ORONBOX_NETWORK_ARCH "aarch64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
  set(ORONBOX_NETWORK_ARCH "x86_64")
else()
  message(FATAL_ERROR "Unsupported Linux architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

set(PREBUILT_DIR
  "${CMAKE_CURRENT_BINARY_DIR}/prebuilt/${ORONBOX_NETWORK_VERSION}")
oronbox_network_fetch(
  "oronbox-network-linux-${ORONBOX_NETWORK_ARCH}.tar.gz"
  "${PREBUILT_DIR}")

add_library(oronbox_network SHARED IMPORTED GLOBAL)
set_target_properties(oronbox_network PROPERTIES
  IMPORTED_LOCATION "${PREBUILT_DIR}/lib/liboronbox_network.so")

set(oronbox_network_bundled_libraries
  "${PREBUILT_DIR}/lib/liboronbox_network.so"
  PARENT_SCOPE)
