defmodule Bme680Test do
  use ExUnit.Case
  doctest Bme680

  test "returns error if an invalid i2c address is given" do
    invalid_i2c_address = 123
    assert { :error, "invalid i2c address #{invalid_i2c_address}. Valid values are 0x76 and 0x77" } ==
      Bme680.start_link([i2c_address: invalid_i2c_address])
  end

  test "starts and stops the GenServer" do
    assert { :ok, pid } = Bme680.start_link(i2c_address: 0x77)
    assert :ok == Bme680.stop(pid)
  end

  test "performs measurements" do
    { :ok, pid } = Bme680.start_link()
    %Bme680.Measurement{
      temperature: temperature,
      pressure: pressure,
      humidity: humidity,
      gas_resistance: gas_resistance
    } = Bme680.measure(pid)

    assert temperature == 21.54
    assert pressure == 1234.21
    assert humidity == 45.72
    assert gas_resistance == 10321
  end

  test "performs async measurements" do
    { :ok, pid } = Bme680.start_link()
    :ok = Bme680.measure_async(pid, self())

    assert_receive %Bme680.Measurement{
      temperature: temperature,
      pressure: pressure,
      humidity: humidity,
      gas_resistance: gas_resistance
    }

    assert temperature == 21.54
    assert pressure == 1234.21
    assert humidity == 45.72
    assert gas_resistance == 10321
  end
end
