add_library(bootloader_limine_x86_64 OBJECT
    common/boot_info_from_limine.cpp
    arch/x86_64/entry.cpp
    $<TARGET_OBJECTS:bootloader_common>
)

configure_bootloader_target(bootloader_limine_x86_64)
