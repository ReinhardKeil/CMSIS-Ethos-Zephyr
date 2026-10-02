/* SPDX-License-Identifier: Apache-2.0 */

/* U85 weights and command streams use non-secure DDR at 0x60000000. */
GROUP_START(DDR4)
SECTION_DATA_PROLOGUE(ethos_model_storage,,SUBALIGN(16))
{
  . = ALIGN(16);
  *(ethos_model)
} GROUP_LINK_IN(DDR4)
GROUP_END(DDR4)

/* Shared_Sram activations use non-secure on-chip SRAM. */
GROUP_START(ETHOS_ARENA)
SECTION_DATA_PROLOGUE(ethos_arena_storage,,SUBALIGN(16))
{
  . = ALIGN(16);
  *(ethos_arena)
} GROUP_LINK_IN(ETHOS_ARENA)
GROUP_END(ETHOS_ARENA)
