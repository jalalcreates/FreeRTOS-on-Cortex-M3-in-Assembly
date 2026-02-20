ENTRY(reset_handler)

MEMORY
{
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 128K
  RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 8K
}

SECTIONS
{
  .text :
  {
    *(.vectors*)
    *(.text*)
  } > FLASH
  .bss :
{
    *(.bss*)
} > RAM

}
