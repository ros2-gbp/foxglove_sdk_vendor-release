cmake_minimum_required(VERSION 3.25)
project(foxglove_sdk_vendor LANGUAGES CXX)

find_package(ament_cmake REQUIRED)

set(FOXGLOVE_SDK_VERSION "v0.26.0")
option(FOXGLOVE_SDK_VENDOR_ALLOW_DOWNLOAD "Allow downloading the Foxglove SDK archive when not vendored" ON)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
  message(FATAL_ERROR "foxglove_sdk_vendor currently only supports Linux hosts.")
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64)$")
  set(FOXGLOVE_SDK_PLATFORM "x86_64-unknown-linux-gnu")
  set(FOXGLOVE_SDK_SHA256 "8fb03b061127788ad708918d186d74d4fdb58718b11cff97c9d605513ab57cc6")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
  set(FOXGLOVE_SDK_PLATFORM "aarch64-unknown-linux-gnu")
  set(FOXGLOVE_SDK_SHA256 "0710f2ec5abc3954acf6203b93a96768dccd19d742af9b78fcd8fbbba5f6225a")
else()
  message(FATAL_ERROR
    "foxglove_sdk_vendor provides prebuilt binaries only for x86_64 and aarch64 on Linux. "
    "Detected processor '${CMAKE_SYSTEM_PROCESSOR}'.")
endif()

set(FOXGLOVE_SDK_URL
  "https://github.com/foxglove/foxglove-sdk/releases/download/sdk/${FOXGLOVE_SDK_VERSION}/foxglove-${FOXGLOVE_SDK_VERSION}-cpp-${FOXGLOVE_SDK_PLATFORM}.zip")
set(FOXGLOVE_SDK_VENDOR_ARCHIVE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor")
set(FOXGLOVE_SDK_LOCAL_ARCHIVE
  "${FOXGLOVE_SDK_VENDOR_ARCHIVE_DIR}/foxglove-${FOXGLOVE_SDK_VERSION}-cpp-${FOXGLOVE_SDK_PLATFORM}.zip")

if(EXISTS "${FOXGLOVE_SDK_LOCAL_ARCHIVE}")
  set(FOXGLOVE_SDK_ARCHIVE "${FOXGLOVE_SDK_LOCAL_ARCHIVE}")
else()
  set(FOXGLOVE_SDK_ARCHIVE
    "${CMAKE_CURRENT_BINARY_DIR}/foxglove-${FOXGLOVE_SDK_VERSION}-${FOXGLOVE_SDK_PLATFORM}.zip")
endif()

set(FOXGLOVE_SDK_EXTRACT_DIR
  "${CMAKE_CURRENT_BINARY_DIR}/foxglove-${FOXGLOVE_SDK_VERSION}-${FOXGLOVE_SDK_PLATFORM}")

set(_foxglove_need_download FALSE)
if(NOT EXISTS "${FOXGLOVE_SDK_ARCHIVE}")
  set(_foxglove_need_download TRUE)
else()
  file(SHA256 "${FOXGLOVE_SDK_ARCHIVE}" _foxglove_existing_sha)
  if(NOT _foxglove_existing_sha STREQUAL "${FOXGLOVE_SDK_SHA256}")
    if("${FOXGLOVE_SDK_ARCHIVE}" STREQUAL "${FOXGLOVE_SDK_LOCAL_ARCHIVE}")
      message(FATAL_ERROR
        "Vendored Foxglove SDK archive at ${FOXGLOVE_SDK_ARCHIVE} does not match expected SHA256. "
        "Please refresh the file.")
    endif()
    set(_foxglove_need_download TRUE)
  endif()
endif()

if(_foxglove_need_download)
  if(NOT FOXGLOVE_SDK_VENDOR_ALLOW_DOWNLOAD)
    message(FATAL_ERROR
      "Foxglove SDK archive not found at ${FOXGLOVE_SDK_LOCAL_ARCHIVE} and downloads are disabled. "
      "Download the appropriate archive from ${FOXGLOVE_SDK_URL} and place it at that path.")
  endif()
  message(STATUS "Downloading Foxglove SDK ${FOXGLOVE_SDK_VERSION} for ${FOXGLOVE_SDK_PLATFORM}")
  file(DOWNLOAD "${FOXGLOVE_SDK_URL}" "${FOXGLOVE_SDK_ARCHIVE}"
    EXPECTED_HASH "SHA256=${FOXGLOVE_SDK_SHA256}"
    SHOW_PROGRESS)
endif()

set(FOXGLOVE_SDK_STAMP "${FOXGLOVE_SDK_EXTRACT_DIR}/.extracted")
if(NOT EXISTS "${FOXGLOVE_SDK_STAMP}")
  file(REMOVE_RECURSE "${FOXGLOVE_SDK_EXTRACT_DIR}")
  file(MAKE_DIRECTORY "${FOXGLOVE_SDK_EXTRACT_DIR}")
  file(ARCHIVE_EXTRACT INPUT "${FOXGLOVE_SDK_ARCHIVE}" DESTINATION "${FOXGLOVE_SDK_EXTRACT_DIR}")
  file(TOUCH "${FOXGLOVE_SDK_STAMP}")
endif()

set(FOXGLOVE_SDK_ROOT "${FOXGLOVE_SDK_EXTRACT_DIR}/foxglove")
set(FOXGLOVE_SDK_INCLUDE_DIR "${FOXGLOVE_SDK_ROOT}/include")
set(FOXGLOVE_SDK_LIBRARY "${FOXGLOVE_SDK_ROOT}/lib/libfoxglove.a")
set(FOXGLOVE_SDK_SHARED_LIBRARY "${FOXGLOVE_SDK_ROOT}/lib/libfoxglove.so")

if(NOT EXISTS "${FOXGLOVE_SDK_LIBRARY}")
  message(FATAL_ERROR
    "Foxglove SDK archive did not provide the expected library at ${FOXGLOVE_SDK_LIBRARY}")
endif()

find_package(foxglove-sdk CONFIG REQUIRED
  PATHS "${FOXGLOVE_SDK_ROOT}"
  NO_DEFAULT_PATH)

# Use the source list and platform link dependencies supplied by the SDK archive.
# REMOTE_ACCESS is kept off to preserve the vendor package's existing static-core
# behavior and avoid imposing the remote-access library's glibc baseline on users.
foxglove_sdk_add_cpp_library(foxglove_sdk_vendor_cpp
  TYPE SHARED
  REMOTE_ACCESS OFF)
target_compile_features(foxglove_sdk_vendor_cpp PUBLIC cxx_std_17)

# The upstream helper points its public interface at the extracted build tree.
# Replace that interface before exporting the target so installed consumers use
# the headers installed by this package instead.
set_target_properties(foxglove_sdk_vendor_cpp PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES
    "$<BUILD_INTERFACE:${FOXGLOVE_SDK_INCLUDE_DIR}>;$<INSTALL_INTERFACE:include>"
  INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
    "$<BUILD_INTERFACE:${FOXGLOVE_SDK_INCLUDE_DIR}>;$<INSTALL_INTERFACE:include>"
)

install(DIRECTORY "${FOXGLOVE_SDK_INCLUDE_DIR}/"
  DESTINATION include)
install(FILES "${FOXGLOVE_SDK_LIBRARY}"
  DESTINATION lib)
if(EXISTS "${FOXGLOVE_SDK_SHARED_LIBRARY}")
  install(FILES "${FOXGLOVE_SDK_SHARED_LIBRARY}"
    DESTINATION lib)
endif()
install(TARGETS foxglove_sdk_vendor_cpp
  EXPORT foxglove_sdk_vendorTargets
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
  RUNTIME DESTINATION bin)
ament_export_include_directories(include)
ament_export_targets(foxglove_sdk_vendorTargets HAS_LIBRARY_TARGET)

ament_package(CONFIG_EXTRAS "foxglove_sdk_vendor-extras.cmake")
