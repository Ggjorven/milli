extern "C" [[noreturn]] void stage2_main()
{
    for (;;)
    {
        asm volatile("hlt");
    }
}
