# Configure imported target for downstream consumers.
get_filename_component(_foxglove_sdk_vendor_prefix "${foxglove_sdk_vendor_DIR}/../../.." REALPATH)
set(_foxglove_sdk_vendor_include "${_foxglove_sdk_vendor_prefix}/include")
set(_foxglove_sdk_vendor_library "${_foxglove_sdk_vendor_prefix}/lib/libfoxglove_sdk_vendor_cpp.so")

if(NOT TARGET foxglove_sdk_vendor::foxglove_sdk)
  if(NOT EXISTS "${_foxglove_sdk_vendor_library}")
    message(FATAL_ERROR
      "foxglove_sdk_vendor expected to find foxglove_sdk_vendor_cpp at '${_foxglove_sdk_vendor_library}'")
  endif()

  add_library(foxglove_sdk_vendor::foxglove_sdk SHARED IMPORTED)
  set_target_properties(foxglove_sdk_vendor::foxglove_sdk PROPERTIES
    IMPORTED_LOCATION "${_foxglove_sdk_vendor_library}"
    INTERFACE_INCLUDE_DIRECTORIES "${_foxglove_sdk_vendor_include}"
  )
endif()

set(foxglove_sdk_vendor_INCLUDE_DIRS "${_foxglove_sdk_vendor_include}")
set(foxglove_sdk_vendor_LIBRARIES foxglove_sdk_vendor::foxglove_sdk)
