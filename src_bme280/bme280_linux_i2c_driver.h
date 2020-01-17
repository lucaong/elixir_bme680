#include <stdint.h>

void user_delay_ms(uint32_t period);
int8_t user_i2c_init(uint8_t device_nr, uint8_t i2c_addr);
int8_t user_i2c_read(uint8_t dev_id, uint8_t reg_addr, uint8_t *reg_data, uint16_t len);
int8_t user_i2c_write(uint8_t dev_id, uint8_t reg_addr, uint8_t *reg_data, uint16_t len);
