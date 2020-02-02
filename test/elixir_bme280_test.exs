defmodule Bme280Test do
  use ExUnit.Case
  doctest Bme280

  test "returns error if an invalid i2c address is given" do
    invalid_i2c_address = 123

    assert {:error, "invalid i2c address #{invalid_i2c_address}. Valid values are 0x76 and 0x77"} ==
             Bme280.start_link(i2c_address: invalid_i2c_address)
  end

  test "starts and stops the GenServer" do
    assert {:ok, pid} = Bme280.start_link(i2c_address: 0x77)
    assert :ok == Bme280.stop(pid)
  end

  test "performs measurements" do
    {:ok, pid} = Bme280.start_link()

    %Bme280.Measurement{
      temperature: temperature,
      pressure: pressure,
      humidity: humidity
    } = Bme280.measure(pid)

    assert temperature == 21.54
    assert pressure == 30.52
    assert humidity == 45.72
  end

  test "performs async measurements" do
    {:ok, pid} = Bme280.start_link()
    :ok = Bme280.measure_async(pid, self())

    assert_receive %Bme280.Measurement{
      temperature: temperature,
      pressure: pressure,
      humidity: humidity
    }

    assert temperature == 21.54
    assert pressure == 30.52
    assert humidity == 45.72
  end
end
