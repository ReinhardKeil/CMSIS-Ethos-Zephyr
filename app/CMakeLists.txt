# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.28.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(test_ethos_u55)

# AC6 6.24's libc++ wrappers must precede the C library headers that Zephyr
# adds explicitly. Apply this to all C++ targets, including TensorFlow Lite
# Micro, so <cstddef> finds libc++'s <stddef.h> before the compiler's C header.
if(CMAKE_CXX_COMPILER_ID STREQUAL "ARMClang")
  get_filename_component(ARMCLANG_BIN_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
  get_filename_component(ARMCLANG_LIBCXX_DIR
    "${ARMCLANG_BIN_DIR}/../include/libcxx" ABSOLUTE)
  target_include_directories(zephyr_interface SYSTEM BEFORE INTERFACE
    "$<$<COMPILE_LANGUAGE:CXX>:${ARMCLANG_LIBCXX_DIR}>"
  )
  # Zephyr 4.4.0 also applies its C-library portability macro to C++. libc++
  # requires constant errno values, so keep that macro limited to C/assembly.
  zephyr_compile_options($<$<COMPILE_LANGUAGE:CXX>:-U_AEABI_PORTABILITY_LEVEL>)
  # Zephyr selects MicroLIB by default, but the C++ runtime pulls in its
  # errno.o alongside Zephyr's errno hook. Use the standard Arm C library.
  function(use_arm_standard_library)
    foreach(link_target zephyr_pre0 zephyr_pre1 zephyr_final)
      if(TARGET ${link_target})
        get_target_property(link_libraries ${link_target} LINK_LIBRARIES)
        list(TRANSFORM link_libraries REPLACE
          "^--library_type=microlib$" "--library_type=standardlib")
        set_property(TARGET ${link_target} PROPERTY LINK_LIBRARIES
          "${link_libraries}")
      endif()
    endforeach()
  endfunction()
  cmake_language(DEFER CALL use_arm_standard_library)

  # armlink resolves references even in unused input objects. Zephyr 4.4's
  # TFLM source list includes a host Python resolver with unbuilt signal ops
  # and omits the shared batch-matmul implementation.
  get_target_property(tflm_sources modules__tflite-micro SOURCES)
  list(FILTER tflm_sources EXCLUDE REGEX "/python_ops_resolver\\.cc$")
  set_property(TARGET modules__tflite-micro PROPERTY SOURCES "${tflm_sources}")
  set(batch_matmul_common
    "${ZEPHYR_TFLITE_MICRO_MODULE_DIR}/tensorflow/lite/micro/kernels/batch_matmul_common.cc")
  if(NOT batch_matmul_common IN_LIST tflm_sources)
    target_sources(modules__tflite-micro PRIVATE "${batch_matmul_common}")
  endif()
endif()

target_include_directories(app PRIVATE src model)

file(GLOB MODEL_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/model/*_model.c"
)

target_sources(app PRIVATE
  src/main.cpp
  model/arena.c
  ${MODEL_SOURCES}
)

# The Vela Shared_Sram configuration uses DDR4 for weights and the command
# stream, and SRAM for scratch/fast scratch. These definitions must also be
# visible while Zephyr's Ethos-U HAL is compiled.
zephyr_compile_definitions(
  NPU_REGIONCFG_0=3
  NPU_REGIONCFG_1=0
  NPU_REGIONCFG_2=0
  NPU_QCONFIG=3
)

zephyr_linker_sources(SECTIONS linker.ld)

