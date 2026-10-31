add_subdirectory(limine)
add_subdirectory(uefi)

add_custom_target(bootloader DEPENDS bootloader_limine bootloader_uefi)
