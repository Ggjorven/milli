namespace boot::uefi::x86_64
{
    using EfiHandle = void*;
    using EfiSystemTable = void*;
    using EfiStatus = unsigned long long;

    inline constexpr static EfiStatus c_EfiSuccessCode = 0;
}

// NOTE: UEFI uses Microsoft's ABI for calling convention, so __attribute__((ms_abi))
extern "C" __attribute__((ms_abi)) boot::uefi::x86_64::EfiStatus efi_main(
    boot::uefi::x86_64::EfiHandle image_handle, boot::uefi::x86_64::EfiSystemTable system_table)
{
    (void)image_handle;
    (void)system_table;

    return boot::uefi::x86_64::c_EfiSuccessCode;
}
