extern "C" [[noreturn]] void kernel_main()
{
    for (;;)
    {
        // TODO: Remove x86 asm
        asm volatile("hlt");
    }
}
