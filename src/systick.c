#include <stm32f1xx.h>
#include "common.h"

void SysTick_handler(void)
{
    BITBAND(GPIOB->ODR)->bit[12] ++;
}