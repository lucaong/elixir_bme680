# Elixir Bme680

[![Build Status](https://travis-ci.org/lucaong/elixir_bme680.svg?branch=master)](https://travis-ci.org/lucaong/elixir_bme680)

An Elixir library to interface with the BME680 environmental sensor.

## Installation

The package can be installed
by adding `elixir_bme680` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_bme680, "~> 0.1.3"}
  ]
end
```

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

## Acknowledgements

This project contains low-level code from the [BME680 driver by
Bosh](https://github.com/BoschSensortec/BME680_driver)
