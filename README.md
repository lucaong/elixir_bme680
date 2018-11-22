# Elixir Bme680

[![Build Status](https://travis-ci.org/lucaong/elixir_bme680.svg?branch=master)](https://travis-ci.org/lucaong/elixir_bme680)

An Elixir library to interface with the BME680 environmental sensor.

## Installation

The package can be installed
by adding `elixir_bme680` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_bme680, "~> 0.1.4"}
  ]
end
```

The Linux I2C driver needs to be installed for this library to work (e.g.
`libi2c-dev` on Debian). If using [Nerves](https://nerves-project.org), the
driver should already be installed by default.


## Usage

```elixir
{:ok, pid} = Bme680.start_link()

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

For more information, read the [API documentation](https://hexdocs.pm/elixir_bme680).

### Note on gas resistance sensor warm up

Note that, due to the nature of the sensor, the gas resistance measurement needs
a warm-up in order to give stable measurements. One possible strategy is to
perform continuous meaurements in a loop until the value stabilizes (e.g.
changing by less than 1% between consecutive measurements). That might take from
a few seconds to several minutes (or more when the sensor is brand new), so it's
adviseable to perform the measurement asynchronously to avoid blocking.


## Acknowledgements

This project contains low-level code from the [BME680 driver by
Bosch](https://github.com/BoschSensortec/BME680_driver)
