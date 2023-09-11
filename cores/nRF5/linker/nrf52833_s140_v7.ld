/* Linker script to configure memory regions. */

SEARCH_DIR(.)
GROUP(-lgcc -lc -lnosys)

/* Inspired by https://github.com/micropython/micropython/blob/master/ports/nrf/boards/memory.ld */
_bootloader_start = 0x72000;

_fs_size = 8K;
ASSERT ((_fs_size % 4096 == 0), "_fs_size must be a multiple of FLASH_NRF52_PAGE_SIZE");
_fs_end = _bootloader_start;
_fs_start = _fs_end - _fs_size;

/* Errata in nRF docs: softdevice ends at 0x27000 not 0x26000. */
_sd_end = 0x27000;
_app_start = _sd_end;
_app_end = _fs_start;

MEMORY
{
  /* https://infocenter.nordicsemi.com/index.jsp?topic=%2Fsdk_nrf5_v16.0.0%2Flib_bootloader.html */
  FLASH (rx)     : ORIGIN = _app_start, LENGTH = _app_end - _app_start
  INTERNAL_FS    : ORIGIN = _fs_start, LENGTH = _fs_size

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

  /* Has to do with the nRF5 SDK fstorage library. Not used by us. */
  .fs_data :
  {
    PROVIDE(__start_fs_data = .);
    KEEP(*(.fs_data))
    PROVIDE(__stop_fs_data = .);
  } > RAM
} INSERT AFTER .data;

SECTIONS
{
  .internal_fs :
  {
    BYTE(0xff)
    FILL(0xff)
    . = _fs_size - 1;
    BYTE(0xff)
  } > INTERNAL_FS
} INSERT BEFORE .data;

INCLUDE "nrf52_common.ld"
