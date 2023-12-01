/* Linker script to configure memory regions. */

SEARCH_DIR(.)
GROUP(-lgcc -lc -lnosys)

/* Inspired by https://github.com/micropython/micropython/blob/master/ports/nrf/boards/memory.ld */
_bootloader_dfu_buffer_size = 8K;
_bootloader_code_start = 0x72000;
_bootloader_start = _bootloader_code_start - _bootloader_dfu_buffer_size;

_fs_size = 8K;
ASSERT ((_fs_size % 4096 == 0), "_fs_size must be a multiple of FLASH_NRF52_PAGE_SIZE");
_fs_end = _bootloader_start;
_fs_start = _fs_end - _fs_size;

/* Errata in nRF docs: softdevice ends at 0x27000 not 0x26000. */
_sd_end = 0x27000;
_app_start = _sd_end;
_app_end = _fs_start;

_ram_size = 128K;
_ram_sd_size = 0x6000;

_ram_start = 0x20000000;
_ram_app_start = _ram_start + _ram_sd_size;
_ram_end = _ram_start + _ram_size;

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
  RAM (rwx) :  ORIGIN = _ram_app_start, LENGTH = _ram_end - _ram_app_start
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
  /*
  Don't actually create an .internal_fs section. Otherwise, the
  DFU bootloader will think that this is part of the application image
  (bank 0) and then flash protect it on boot, preventing the internal FS
  from working and causing a restart on fal_erase.
  Moreover, there are no guarantees that the internal FS will remain
  intact after a DFU update, and in fact we would like it to be
  reformatted on every update.
  */
  /*
  .internal_fs :
  {
    *(.internal_fs)
    BYTE(0xff)
    FILL(0xff)
    . = _fs_size - 1;
    BYTE(0xff)
  } > INTERNAL_FS
  */

  /*
    Keep the SEGGER RTT control block in a fixed place (0x0), so that we can
    see both bootloader and application output.
    To pull this off, the .rtt* sections of this .elf and of the bootloader
    firmware must match exactly. They must both start on the same address
    and contain the same exact RTT control block with identical addresses
    and sizes (see _SEGGER_RTT, _acUpBuffer, _acDownBuffer symbols).
    To line them up, check SEGGER_RTT_Conf.h here and sdk_config.h on the
    bootloader. Also check nrf_common.ld on the bootloader's side and add
    the same section definition as below, right before the .data section.
    Use NOLOAD to exclude the section from being flashed, since it is located in
    RAM.
  */
  .rtt_cb (NOLOAD) : {} > RAM
  .rtt_buffers (NOLOAD) : {} > RAM
} INSERT BEFORE .data;

INCLUDE "nrf52_common.ld"
