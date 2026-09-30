# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.28.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(test_ethos_u55)

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

