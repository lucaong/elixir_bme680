#include <stdlib.h>
#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <poll.h>
#include <unistd.h>
#include "bme680.h"
#include "bme680_defs.h"
#include "bme680_linux_i2c_driver.h"

#define MAX_READ_BUFFER_LEN 32

int poll_input() {
  int timeout = 5000;
  struct pollfd fd;
  fd.fd = STDIN_FILENO;
  fd.events = POLLIN;
  fd.revents = 0;
  return poll(&fd, 1, timeout);
}

void output_measurement(struct bme680_dev gas_sensor, uint16_t meas_period) {
  struct bme680_field_data data;
  int8_t rslt = BME680_OK;

  rslt = bme680_set_sensor_mode(&gas_sensor); /* Trigger the next measurement */
  user_delay_ms(meas_period); /* Delay till the measurement is ready */
  rslt = bme680_get_sensor_data(&data, &gas_sensor);

  char output[40];

  if (data.status & BME680_GASM_VALID_MSK) {
    snprintf(output, 40, "T:%06.2f,P:%07.2f,H:%06.2f,G:%06d", data.temperature / 100.0f,
        data.pressure / 100.0f, data.humidity / 1000.0f, data.gas_resistance);
  } else {
    snprintf(output, 40, "T:%06.2f,P:%07.2f,H:%06.2f", data.temperature / 100.0f,
        data.pressure / 100.0f, data.humidity / 1000.0f);
  }

  puts(output);
}

int main(int argc, char* argv[])
{
  struct bme680_dev gas_sensor;
  uint8_t i2c_device_n = 1;
  uint8_t i2c_addr = BME680_I2C_ADDR_PRIMARY;

  if (argc > 1) {
    i2c_device_n = (uint8_t) atoi(argv[1]);
  }

  if (argc > 2) {
    i2c_addr = (uint8_t) atoi(argv[2]);
    if (i2c_addr != BME680_I2C_ADDR_PRIMARY && i2c_addr != BME680_I2C_ADDR_SECONDARY) {
      err(EXIT_FAILURE, "Invalid i2c address: %d", i2c_addr);
      return -1;
    }
  }

  user_i2c_init(i2c_device_n, i2c_addr);

  gas_sensor.dev_id = i2c_addr;
  gas_sensor.intf = BME680_I2C_INTF;
  gas_sensor.read = user_i2c_read;
  gas_sensor.write = user_i2c_write;
  gas_sensor.delay_ms = user_delay_ms;
  /* amb_temp can be set to 25 prior to configuring the gas sensor
   * or by performing a few temperature readings without operating the gas sensor.
   */
  gas_sensor.amb_temp = 25;


  int8_t rslt = BME680_OK;
  rslt = bme680_init(&gas_sensor);

  uint8_t set_required_settings;

  /* Set the temperature, pressure and humidity settings */
  gas_sensor.tph_sett.os_hum = BME680_OS_2X;
  gas_sensor.tph_sett.os_pres = BME680_OS_4X;
  gas_sensor.tph_sett.os_temp = BME680_OS_8X;
  gas_sensor.tph_sett.filter = BME680_FILTER_SIZE_3;

  /* Set the remaining gas sensor settings and link the heating profile */
  gas_sensor.gas_sett.run_gas = BME680_ENABLE_GAS_MEAS;
  /* Create a ramp heat waveform in 3 steps */
  gas_sensor.gas_sett.heatr_temp = 320; /* degree Celsius */
  gas_sensor.gas_sett.heatr_dur = 150; /* milliseconds */

  /* Select the power mode */
  /* Must be set before writing the sensor configuration */
  gas_sensor.power_mode = BME680_FORCED_MODE;

  /* Set the required sensor settings needed */
  set_required_settings = BME680_OST_SEL | BME680_OSP_SEL | BME680_OSH_SEL | BME680_FILTER_SEL
    | BME680_GAS_SENSOR_SEL;

  /* Set the desired sensor configuration */
  rslt = bme680_set_sensor_settings(set_required_settings,&gas_sensor);

  /* Set the power mode */
  rslt = bme680_set_sensor_mode(&gas_sensor);

  /* Get the total measurement duration so as to sleep or wait till the
   * measurement is complete */
  uint16_t meas_period;
  bme680_get_profile_dur(&meas_period, &gas_sensor);

  user_delay_ms(meas_period);

  char buffer[MAX_READ_BUFFER_LEN];

  while(1)
  {
    int poll_status = poll_input();
    if (poll_status > 0) {
      if (fgets(buffer, MAX_READ_BUFFER_LEN, stdin) == NULL) {
        return 1;
      }

      if (strcmp("measure", buffer) == 0) {
        output_measurement(gas_sensor, meas_period);
      } else {
        err(EXIT_FAILURE, "Invalid command %d", buffer[0]);
      }
    }
  }
}
