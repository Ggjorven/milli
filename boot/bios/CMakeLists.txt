add_library(bootloader_bios_x86 OBJECT
    stage1.S
    realmode.S
    transition.S
    stage2.cpp
    $<TARGET_OBJECTS:bootloader_common>
)

configure_bootloader_target(bootloader_bios_x86)

# Legacy BIOS has only an x86 entry environment. stage1 and realmode begin in 16-bit real mode.
set_source_files_properties(stage1.S realmode.S PROPERTIES
    COMPILE_OPTIONS "-m16"
)
