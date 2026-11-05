typedef void* EfiHandle;
typedef void* EfiSystemTable;
typedef unsigned long long EfiStatus;

static const EfiStatus EFI_SUCCESS_CODE = 0;

// NOTE: UEFI uses Microsoft's ABI for calling convention, so __attribute__((ms_abi))
__attribute__((ms_abi)) EfiStatus efi_main(EfiHandle image_handle, EfiSystemTable system_table)
{
    (void)image_handle;
    (void)system_table;

    return EFI_SUCCESS_CODE;
}
