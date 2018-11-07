#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <err.h>
#include <errno.h>
#include <time.h>
#include <stdio.h>
#include "linux/i2c-dev.h"

#define USER_I2C_BUFFER_LENGTH 128

int i2c_fd = 0;

void user_delay_ms(uint32_t period)
{
  struct timespec ts;
  ts.tv_sec = period / 1000;
  ts.tv_nsec = (period % 1000) * 1000000;
  nanosleep(&ts, NULL);
}

int8_t user_i2c_init(uint8_t device_nr, uint8_t i2c_addr)
{
  char i2c_device_name[20];
  snprintf(i2c_device_name, 19, "/dev/i2c-%d", device_nr);

  if (!i2c_fd) {
    i2c_fd = open(i2c_device_name, O_RDWR);

    if (i2c_fd < 0) {
      err(EXIT_FAILURE, "open i2c device: %d", i2c_fd);
      return (uint8_t) -1;
    }
  }

  int status = ioctl(i2c_fd, I2C_SLAVE_FORCE, i2c_addr);

  if (status < 0) {
    err(EXIT_FAILURE, "set i2c slave address: %d", status);
    return (uint8_t) -1;
  }

  return (uint8_t) 0;
}

int8_t user_i2c_read(uint8_t dev_id, uint8_t reg_addr, uint8_t *reg_data, uint16_t len)
{
    /*
     * The parameter dev_id can be used as a variable to store the I2C address of the device
     */

    /*
     * Data on the bus should be like
     * |------------+---------------------|
     * | I2C action | Data                |
     * |------------+---------------------|
     * | Start      | -                   |
     * | Write      | (reg_addr)          |
     * | Stop       | -                   |
     * | Start      | -                   |
     * | Read       | (reg_data[0])       |
     * | Read       | (....)              |
     * | Read       | (reg_data[len - 1]) |
     * | Stop       | -                   |
     * |------------+---------------------|
     */

    int n;

    uint8_t rbuf[1];
    rbuf[0] = reg_addr;

    n = write(i2c_fd, rbuf, 1);
    if (n != 1) {
      err(EXIT_FAILURE, "i2c write: %d", n);
      return (uint8_t) -1;
    }

    n = read(i2c_fd, reg_data, len);
    if (n != len) {
      err(EXIT_FAILURE, "i2c read: %d", n);
      return (uint8_t) -1;
    }

    return (uint8_t) 0;
}

int8_t user_i2c_write(uint8_t dev_id, uint8_t reg_addr, uint8_t *reg_data, uint16_t len)
{
    /*
     * The parameter dev_id can be used as a variable to store the I2C address of the device
     */

    /*
     * Data on the bus should be like
     * |------------+---------------------|
     * | I2C action | Data                |
     * |------------+---------------------|
     * | Start      | -                   |
     * | Write      | (reg_addr)          |
     * | Write      | (reg_data[0])       |
     * | Write      | (....)              |
     * | Write      | (reg_data[len - 1]) |
     * | Stop       | -                   |
     * |------------+---------------------|
     */

    uint8_t buf[USER_I2C_BUFFER_LENGTH];
    int i;

    buf[0] = reg_addr;

    for (i = 0; i < len; i++) {
      buf[i + 1] = reg_data[i];
    }

    int n = write(i2c_fd, buf, len + 1);
    if (n != len + 1) {
      err(EXIT_FAILURE, "i2c write: %d", n);
      return (uint8_t) -1;
    }

    return (uint8_t) 0;
}
