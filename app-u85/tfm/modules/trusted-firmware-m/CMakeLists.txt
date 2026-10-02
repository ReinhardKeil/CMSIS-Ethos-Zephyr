# SPDX-License-Identifier: Apache-2.0

# Zephyr's TF-M glue only recognizes the Zephyr SDK and gnuarmemb variants.
# Keep this override scoped to the secure build; the NS compiler stays AC6/GCC.
if(CONFIG_BUILD_WITH_TFM)
  find_program(U85_TFM_GCC arm-none-eabi-gcc REQUIRED)
  get_filename_component(U85_TFM_GCC_BIN "${U85_TFM_GCC}" DIRECTORY)
  get_filename_component(GNUARMEMB_TOOLCHAIN_PATH "${U85_TFM_GCC_BIN}" DIRECTORY)
  set(ZEPHYR_TOOLCHAIN_VARIANT gnuarmemb)

  # Zephyr's TF-M GNU toolchain assumes the SDK's Picolibc. Arm GCC ships
  # Newlib instead. Adapt a build-local copy, leaving the west checkout intact.
  set(U85_TFM_TOOLCHAIN "${CMAKE_CURRENT_BINARY_DIR}/toolchain_GNUARM_Newlib.cmake")
  file(READ "${ZEPHYR_TRUSTED_FIRMWARE_M_MODULE_DIR}/toolchain_GNUARM.cmake" U85_TFM_TOOLCHAIN_TEXT)
  string(REPLACE "-specs=picolibc.specs" "-specs=nosys.specs" U85_TFM_TOOLCHAIN_TEXT "${U85_TFM_TOOLCHAIN_TEXT}")
  string(REPLACE "\${CMAKE_CURRENT_LIST_DIR}/cmake/set_extensions.cmake"
    "${ZEPHYR_TRUSTED_FIRMWARE_M_MODULE_DIR}/cmake/set_extensions.cmake"
    U85_TFM_TOOLCHAIN_TEXT "${U85_TFM_TOOLCHAIN_TEXT}")
  file(CONFIGURE OUTPUT "${U85_TFM_TOOLCHAIN}" CONTENT "${U85_TFM_TOOLCHAIN_TEXT}" @ONLY)
  set_property(TARGET zephyr_property_target APPEND PROPERTY TFM_CMAKE_OPTIONS
    "-DTFM_TOOLCHAIN_FILE=${U85_TFM_TOOLCHAIN}"
    "-DCONFIG_TFM_INCLUDE_STDLIBC=ON")
  if(CMAKE_HOST_WIN32)
    # TF-M provisioning scatter files match *provisioning_data.o by name.
    set_property(TARGET zephyr_property_target APPEND PROPERTY TFM_CMAKE_OPTIONS
      "-DCMAKE_INTERMEDIATE_DIR_STRATEGY=FULL")
  endif()
endif()
add_subdirectory("${ZEPHYR_BASE}/modules/trusted-firmware-m" "${CMAKE_CURRENT_BINARY_DIR}/upstream")
