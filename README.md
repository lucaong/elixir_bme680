# Elixir Bme680

[![Build Status](https://travis-ci.org/lucaong/elixir_bme680.svg?branch=master)](https://travis-ci.org/lucaong/elixir_bme680) [![Hex Version](https://img.shields.io/hexpm/v/elixir_bme680.svg)](https://hex.pm/packages/elixir_bme680) [![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/elixir_bme680/)

An Elixir library to interface with the BME680 and BME280 environmental sensors. The BME680
provides measurements of temperature, pressure, humidity, and gas resistance
(which is a proxy of indoor air quality). The BME280 is a lower cost device that only
provides measurements of temperature, pressure, humidity.

## Installation

The package can be installed
by adding `elixir_bme680` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_bme680, "~> 0.2.2"}
  ]
end
```

The Linux I2C driver needs to be installed for this library to work (e.g.
`libi2c-dev` on Debian). If using [Nerves](https://nerves-project.org), the
driver should already be installed by default.

## Configuration

Depending on your hardware configuration, you may need to specify options to `Bme680.start_link/2` or `Bme280.start_link/2`.
For example, the i2c address of the sensor can be `0x76` or `0x77`.

## Usage with the BME680

```elixir
{:ok, pid} = Bme680.start_link(i2c_address: 0x76)

measurement = Bme680.measure(pid)

# Measurement is like:
#
#   %Bme680.Measurement{
#     temperature: 21.74,
#     pressure: 1090.52,
#     humidity: 45.32,
#     gas_resistance: 10235
#   }
#
# Where temperature is in degrees Celsius, pressure in hPa, humidity in %
# relative humidity, and gas_resistance in Ohm
```

For more information, read the [API documentation](https://hexdocs.pm/elixir_bme680/Bme680.html).

### Sensor compatibility

The default setting has been tested on the [Pimoroni
BME680](https://shop.pimoroni.com/products/bme680-breakout). The [Adafruit
BME680](https://www.adafruit.com/product/3660) requires using a different i2c
address. For the Adafruit, pass in the `i2c_address` option with value `0x77` as
follows:

```elixir
Bme680.start_link(i2c_address: 0x77)
```

### Note on gas resistance sensor warm up on the BME680

Note that, due to the nature of the BME680 gas resistance sensor, the gas
resistance measurement needs a warm-up in order to give stable measurements. One
possible strategy is to perform continuous meaurements in a loop until the value
stabilizes. That might take from a few seconds to several minutes (or more when
the sensor is brand new).

## Usage with the BME280

```elixir
{:ok, pid} = Bme280.start_link(i2c_address: 0x76)

measurement = Bme280.measure(pid)

# Measurement is like:
#
#   %Bme280.Measurement{
#     temperature: 21.74,
#     pressure: 30.52,
#     humidity: 45.32
#   }
#
# Where temperature is in degrees Celsius, pressure in inHg, humidity in %
# relative humidity
```

For more information, read the [API documentation](https://hexdocs.pm/elixir_bme680/Bme280.html).

### Sensor compatibility

The default setting has been tested on the [HiLetgo
BME280](https://www.amazon.com/gp/product/B01N47LZ4P/).

## Acknowledgements

This project contains low-level code from the [BME680 driver by
Bosch](https://github.com/BoschSensortec/BME680_driver) and the
[BME280 driver by Bosch](https://github.com/BoschSensortec/BME280_driver).
