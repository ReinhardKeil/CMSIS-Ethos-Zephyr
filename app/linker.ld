/* SPDX-License-Identifier: Apache-2.0 */

/*
 * The Corstone-300 DDR4 region is visible to both the CPU and Ethos-U. Keep
 * the Vela command streams and the TFLM arena together there. The arena is
 * reused by the two interpreters, which run sequentially.
 */
GROUP_START(DDR4)
SECTION_DATA_PROLOGUE(_ETHOS_STORAGE_SECTION_NAME,,SUBALIGN(16))
{
  . = ALIGN(16);
  *(ethos_model ethos_arena)
} GROUP_LINK_IN(DDR4)
GROUP_END(DDR4)

