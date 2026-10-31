add_library(bootloader_limine_x86_64 OBJECT
    arch/x86_64/limine_boot.cpp
)

target_compile_options(bootloader_limine_x86_64 PRIVATE
    -ffreestanding
    -fno-exceptions
    -fno-rtti
    -fno-stack-protector
    -fno-pie
)

add_custom_target(bootloader_limine DEPENDS bootloader_limine_x86_64)
