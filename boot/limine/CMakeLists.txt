add_library(bootloader_limine_x86_64 OBJECT
    common/boot_info_from_limine.c
    arch/${ARCHITECTURE}/entry.c
    $<TARGET_OBJECTS:bootloader_common>
)

configure_bootloader_target(bootloader_limine_x86_64)

# TODO: Add back run targets
