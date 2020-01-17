#include <stdlib.h>
#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <poll.h>
#include <unistd.h>
#include "bme280.h"
#include "bme280_defs.h"
#include "bme280_linux_i2c_driver.h"

#define MAX_READ_BUFFER_LEN 32
#define MAX_WRITE_BUFFER_LEN 64

int poll_input() {
  int timeout = 5000;
  struct pollfd fd;
  fd.fd = STDIN_FILENO;
  fd.events = POLLIN;
  fd.revents = 0;
  return poll(&fd, 1, timeout);
}

void output_measurement(struct bme280_dev *gas_sensor, uint16_t req_delay) {
  struct bme280_data data;
  int8_t rslt = BME280_OK;

  // This may need to be BME280_FORCED_MODE
  rslt = bme280_set_sensor_mode(BME280_FORCED_MODE, gas_sensor);
  if (rslt != BME280_OK) {
      err(EXIT_FAILURE, "Bme280 set sensor mode: %d", rslt);
  }

  /* Wait for the measurement to complete and print data @25Hz */
  user_delay_ms(req_delay); /* Delay till the measurement is ready */

  rslt = bme280_get_sensor_data(BME280_ALL, &data, gas_sensor);
  if (rslt != BME280_OK) {
      err(EXIT_FAILURE, "Bme280 get sensor data: %d", rslt);
  }

  char output[MAX_WRITE_BUFFER_LEN];

  /*
   * temperature is degrees C
   * humidity is % relative humidity
   * pressure is inHg
   */

  snprintf(output, MAX_WRITE_BUFFER_LEN, "T:%08.4f,P:%08.4f,H:%08.4f", data.temperature / 100.0f,
      data.pressure / 338600.0f, data.humidity / 1024.0f);

  fprintf(stdout, "%s\n", output);
  fflush(stdout);
}

int main(int argc, char* argv[])
{
  struct bme280_dev gas_sensor;
  uint8_t i2c_device_n = 1;
  uint8_t i2c_addr = BME280_I2C_ADDR_PRIM;
  uint32_t req_delay;

  if (argc > 1) {
    i2c_device_n = (uint8_t) atoi(argv[1]);
  }

  if (argc > 2) {
    i2c_addr = (uint8_t) atoi(argv[2]);
    if (i2c_addr != BME280_I2C_ADDR_PRIM && i2c_addr != BME280_I2C_ADDR_SEC) {
      err(EXIT_FAILURE, "Invalid i2c address: %d", i2c_addr);
      return -1;
    }
  }

  user_i2c_init(i2c_device_n, i2c_addr);

  gas_sensor.dev_id = i2c_addr;
  gas_sensor.intf = BME280_I2C_INTF;
  gas_sensor.read = user_i2c_read;
  gas_sensor.write = user_i2c_write;
  gas_sensor.delay_ms = user_delay_ms;
  /* amb_temp can be set to 25 prior to configuring the gas sensor
   * or by performing a few temperature readings without operating the gas sensor.
   */
  // gas_sensor.amb_temp = 25;

  int8_t rslt = bme280_init(&gas_sensor);
  if (rslt != BME280_OK) {
      err(EXIT_FAILURE, "Bme280 init: %d", rslt);
      return -1;
  }

  uint8_t set_required_settings;

  /* Set the temperature, pressure and humidity settings */
  gas_sensor.settings.osr_h = BME280_OVERSAMPLING_1X;
  gas_sensor.settings.osr_p = BME280_OVERSAMPLING_16X;
  gas_sensor.settings.osr_t = BME280_OVERSAMPLING_2X;
  gas_sensor.settings.filter = BME280_FILTER_COEFF_16; // BME280_FILTER_SIZE_3;

  /* Set the required sensor settings needed */
  set_required_settings = BME280_OSR_TEMP_SEL | BME280_OSR_PRESS_SEL | BME280_OSR_HUM_SEL | BME280_FILTER_SEL;

  /* Set the desired sensor configuration */
  rslt = bme280_set_sensor_settings(set_required_settings, &gas_sensor);
  if (rslt != BME280_OK) {
      err(EXIT_FAILURE, "Bme280 set sensor settings: %d", rslt);
      return -1;
  }

	/*Calculate the minimum delay required between consecutive measurement based upon the sensor enabled
     *  and the oversampling configuration. */
  req_delay = bme280_cal_meas_delay(&gas_sensor.settings);

  /* Set the power mode */
  rslt = bme280_set_sensor_mode(BME280_FORCED_MODE, &gas_sensor);
  if (rslt != BME280_OK) {
      err(EXIT_FAILURE, "Bme280 set sensor mode: %d", rslt);
      return -1;
  }

  user_delay_ms(req_delay);
  char buffer[MAX_READ_BUFFER_LEN];

  while(1)
  {
    int poll_status = poll_input();
    if (poll_status > 0) {
      if (fgets(buffer, MAX_READ_BUFFER_LEN, stdin) == NULL) {
        return 1;
      }

      if (strcmp("measure\n", buffer) == 0) {
        output_measurement(&gas_sensor, req_delay);
      } else {
        err(EXIT_FAILURE, "Invalid command %s", buffer);
      }
    }
  }
}
