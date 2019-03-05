/*
 * stuff of startup
 */
#include <stdint.h>
/*----------Symbols defined in linker script----------------------------------*/  
extern uint32_t _sidata;    /*!< Start address for the initialization 
                                      values of the .data section.            */
extern uint32_t _sdata;     /*!< Start address for the .data section     */    
extern uint32_t _edata;     /*!< End address for the .data section       */    
extern uint32_t _sbss;      /*!< Start address for the .bss section      */
extern uint32_t _ebss;      /*!< End address for the .bss section        */      
//extern void _eram;               /*!< End address for ram                     */

/*
    1. 对系统的 .data 区域的变量进行初始化
    2. 对 .bss 的区域的变量清零
*/
void mem_init(void) __attribute__ ((section(".init")));
void mem_init(void)
{
    /* Initialize data and bss */
    uint32_t *pulSrc,*pulDest;

    /* Copy the data segment initializers from flash to SRAM */
    pulSrc = &_sidata;


    for(pulDest = &_sdata; pulDest < &_edata; )
    {
        *(pulDest++) = *(pulSrc++);
    }
  
    /* Zero fill the bss segment.  This is done with inline assembly since this
       will clear the value of pulDest if it is not kept in a register. */
    __asm("  ldr     r0, =_sbss\n"
        "  ldr     r1, =_ebss\n"
        "  mov     r2, #0\n"
        "  .thumb_func\n"
        "zero_loop:\n"
        "    cmp     r0, r1\n"
        "    it      lt\n"
        "    strlt   r2, [r0], #4\n"
        "    blt     zero_loop");

}
