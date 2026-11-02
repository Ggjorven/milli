__attribute__((noreturn)) void kernel_main(void)
{
    for (;;)
    {
        // TODO: Remove x86 asm
        __asm__ __volatile__("hlt");
    }
}
