add_library(bootloader_uefi_x86_64 OBJECT
    arch/x86_64/entry.cpp
)

target_compile_options(bootloader_uefi_x86_64 PRIVATE
    -ffreestanding
    -fno-exceptions
    -fno-rtti
    -fno-stack-protector
    -fno-pie
)

add_custom_target(bootloader_uefi DEPENDS bootloader_uefi_x86_64)
