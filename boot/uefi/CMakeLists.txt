add_library(bootloader_uefi_x86_64 OBJECT
    common/file_loader.cpp
    common/memory_map.cpp
    arch/x86_64/entry.cpp
    arch/x86_64/paging.cpp
    $<TARGET_OBJECTS:bootloader_common>
)

configure_bootloader_target(bootloader_uefi_x86_64)
