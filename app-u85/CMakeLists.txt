# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.28.0)

# Build TF-M with GCC even when the non-secure application uses AC6.
list(APPEND MODULE_EXT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/tfm")
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(test_ethos_u85)

target_include_directories(app PRIVATE ../app/model)
target_compile_definitions(app PRIVATE ETHOS_U_TEST_NAME="Ethos-U85")
file(GLOB MODEL_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/model/*_model.c")
target_sources(app PRIVATE ../app/src/main.cpp ../app/model/arena.c ${MODEL_SOURCES})

# Shared_Sram: weights and command stream use DDR, scratch uses on-chip SRAM.
zephyr_compile_definitions(NPU_REGIONCFG_0=3 NPU_REGIONCFG_1=0 NPU_REGIONCFG_2=0 NPU_QCONFIG=3)
if(CONFIG_ARMCLANG_STD_LIBC)
  # Zephyr sets this for C; TFLM's C++ also needs the same errno ABI.
  zephyr_compile_definitions(_AEABI_PORTABILITY_LEVEL=1)
endif()
zephyr_linker_sources(SECTIONS linker.ld)

# Reuse the Ethos-U module selected by the Zephyr manifest in secure firmware.
set_property(TARGET zephyr_property_target APPEND PROPERTY TFM_CMAKE_OPTIONS
  "-DETHOS_DRIVER_PATH=${ZEPHYR_HAL_ETHOS_U_MODULE_DIR}")
