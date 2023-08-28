/* Linker script to configure memory regions. */

SEARCH_DIR(.)
GROUP(-lgcc -lc -lnosys)

MEMORY
{
  /* https://infocenter.nordicsemi.com/index.jsp?topic=%2Fsdk_nrf5_v16.0.0%2Flib_bootloader.html */
  /* Errata in nRF docs: softdevice ends at 0x27000 not 0x26000. */
  /* 0x6D000 - 0x78000: used by InternalFileSystem */
  /* TODO: whittle this down to 3 pages (12288 bytes), so the new InternalFS flash range is 0x75000 - 0x78000 */
  /*       and we get more app space, and in the future a bootloader can use these 3 pages of space for OTA. */
  FLASH (rx)     : ORIGIN = 0x27000, LENGTH = 0x6D000 - 0x27000

  /* SRAM required by Softdevice depend on
   * - Attribute Table Size (Number of Services and Characteristics)
   * - Vendor UUID count
   * - Max ATT MTU
   * - Concurrent connection peripheral + central + secure links
   * - Event Len, HVN queue, Write CMD queue
   */
  RAM (rwx) :  ORIGIN = 0x20006000, LENGTH = 0x20020000 - 0x20006000
}

SECTIONS
{
  . = ALIGN(4);
  .svc_data :
  {
    PROVIDE(__start_svc_data = .);
    KEEP(*(.svc_data))
    PROVIDE(__stop_svc_data = .);
  } > RAM

  .fs_data :
  {
    PROVIDE(__start_fs_data = .);
    KEEP(*(.fs_data))
    PROVIDE(__stop_fs_data = .);
  } > RAM
} INSERT AFTER .data;

INCLUDE "nrf52_common.ld"
