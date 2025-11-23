# foxglove_sdk_vendor

ROS 2 vendor package that downloads the prebuilt [Foxglove SDK](https://docs.foxglove.dev/docs/sdk)
release artifacts, installs the public headers, and builds a shared library that contains the SDK's
C++ wrapper sources linked against the bundled `libfoxglove.a`. Downstream packages only need to
link against the exported `foxglove_sdk_vendor::foxglove_sdk` target to obtain both the wrapper code
and the underlying SDK runtime.

Currently the package pulls Foxglove SDK `v0.15.1` for Linux hosts (`x86_64` or `aarch64`). The
archive is vendored under `vendor/` (see below), verified via the SHA256 value published on the
[GitHub release page](https://github.com/foxglove/foxglove-sdk/releases?q=sdk%2F&expanded=true), and
extracted into the build tree before the headers, `libfoxglove.a`, `libfoxglove.so` (if provided),
and the compiled wrapper library are installed to `install/`.

## Using the vendor package

```cmake
find_package(foxglove_sdk_vendor REQUIRED)

add_executable(example_node src/example_node.cpp)
target_link_libraries(example_node PRIVATE foxglove_sdk_vendor::foxglove_sdk)
```

The config exported by `ament_package()` also sets
`foxglove_sdk_vendor_INCLUDE_DIRS` / `foxglove_sdk_vendor_LIBRARIES` so you may use those variables
directly if you prefer.

## Updating the bundled SDK

1. Pick the desired SDK release from the [Foxglove SDK docs](https://docs.foxglove.dev/docs/sdk) or
   the GitHub releases page.
2. Update `FOXGLOVE_SDK_VERSION`, URLs, and SHA256 values in `CMakeLists.txt`.
3. Verify the list of wrapper sources (`FOXGLOVE_SDK_WRAPPER_SOURCES`) matches the new release.
4. Rebuild the workspace so the new archive is downloaded, compiled, and installed.

If you need support for an additional platform, extend the processor detection logic in
`CMakeLists.txt` with the new archive name and checksum.

## Vendored archives and offline builds

ROS 2 release builds typically forbid downloading external artifacts. To keep those builds
reproducible, the `vendor/` directory already contains the Foxglove SDK archives for x86_64 and
aarch64 Linux. At configure time the package prefers those archives. If you delete them (or if you
want to work with a different version) either:

1. Place the matching `foxglove-<version>-cpp-<platform>.zip` into `vendor/`, **or**
2. Configure with `-DFOXGLOVE_SDK_VENDOR_ALLOW_DOWNLOAD=ON` so CMake can fetch the archive directly
   from the GitHub release you specify in `CMakeLists.txt`.

Downloads are enabled by default for developer convenience, but the CMake option makes it easy to
enforce the no-network policy in CI/release pipelines.

## License

The vendor glue code is MIT licensed. The Foxglove SDK binaries that are downloaded at build time
remain under the upstream MIT license published by Foxglove.
