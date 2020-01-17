defmodule Bme280 do
  @moduledoc """
  `elixir_bme280` provides a high level abstraction to interface with the
  BME280 environmental sensor on Linux platforms.
  """
  use Bitwise
  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    defstruct port: nil, subscribers: [], async_subscribers: [], measuring: false
  end

  defmodule Measurement do
    @moduledoc false
    defstruct temperature: nil, pressure: nil, humidity: nil
  end


  @doc """
  Starts and links the `Bme280` GenServer.

  Options:
    - `i2c_device_number` is the number of the i2c device, e.g. 1 for `/dev/i2c-1`
    - `i2c_address` i2c address of the sensor. It can be only `0x76` or `0x77`
    - `temperature_offset` is an offset, in degrees Celsius, that will be
      subtracted to temperature measurements in order to compensate for the internal
      heating of the device. It's typically around 4 or 5 degrees, and also
      affects relative humidity calculations
  """
  @spec start_link([ i2c_device_number: integer, i2c_address: 0x76 | 0x77, temperature_offset: non_neg_integer ], [ term ]) :: GenServer.on_start()
  def start_link(bme_opts \\ [], opts \\ []) do
    i2c_device_number = Keyword.get(bme_opts, :i2c_device_number, 1)
    i2c_address = Keyword.get(bme_opts, :i2c_address, 0x76)
    temperature_offset = Keyword.get(bme_opts, :temperature_offset, 0)

    if Enum.member?([0x76, 0x77], i2c_address) do
      arg = [i2c_device_number, i2c_address, temperature_offset]
      GenServer.start_link(__MODULE__, arg, opts)
    else
      { :error, "invalid i2c address #{i2c_address}. Valid values are 0x76 and 0x77" }
    end
  end

  @doc """
  Perform a measurement on the BME280 sensor and synchronously return it

  Measurements are structs like:
  ```
  %Bme280.Measurement{
    temperature: 21.74,
    pressure: 30.52,
    humidity: 45.32
  }
  ```
  """
  @spec measure(GenServer.server()) :: %Measurement{ temperature: float, pressure: float, humidity: float | nil }
  def measure(pid) do
    GenServer.call(pid, :measure)
  end

  @doc """
  Perform a measurement on the BME280 sensor and asynchronously send the result
  as a message to the pid in `send_to`
  """
  @spec measure_async(GenServer.server(), pid) :: :ok
  def measure_async(pid, send_to) do
    GenServer.cast(pid, {:measure_async, send_to})
  end

  @doc """
  Gracefully stops the `Bme280` GenServer.
  """
  @spec stop(GenServer.server()) :: :ok
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  # GenServer callbacks

  def init([i2c_device_number, i2c_address, temperature_offset]) do
    executable_dir = Application.get_env(:elixir_bme680, :executable_dir, :code.priv_dir(:elixir_bme680))

    port = Port.open({:spawn_executable, executable_dir ++ '/bme280'}, [
      {:args, ["#{i2c_device_number}", "#{i2c_address}", "#{temperature_offset}"]},
      {:line, 64},
      :use_stdio,
      :binary,
      :exit_status
    ])

    {:ok, %State{ port: port, measuring: false, subscribers: [] }}
  end

  def handle_call(:measure, from, state = %State{ port: port, subscribers: subscribers, measuring: measuring }) do
    unless measuring, do: Port.command(port, "measure\n")
    { :noreply, %State{ state | measuring: true, subscribers: [from | subscribers] } }
  end

  def handle_cast({:measure_async, pid}, state = %State{ port: port, async_subscribers: subs, measuring: measuring }) do
    unless measuring, do: Port.command(port, "measure\n")
    { :noreply, %State{ state | measuring: true, async_subscribers: [pid | subs] } }
  end

  def handle_cast(:stop, state) do
    { :stop, :normal, state }
  end

  def handle_info({p, {:data, {:eol, line}}}, %State{ port: p, subscribers: subs, async_subscribers: async_subs }) do
    measurement = decode_measurement(line)
    for pid <- subs, do: GenServer.reply(pid, measurement)
    for pid <- async_subs, do: send(pid, measurement)
    { :noreply, %State{ port: p, measuring: false, subscribers: [], async_subscribers: [] } }
  end

  def handle_info({port, {:exit_status, exit_status}}, state = %State{ port: port }) do
    { :stop, exit_status, state }
  end

  # Private helper functions

  defp convert_float(s) do
    try do
      String.to_float(s)
    catch
      e, v -> Logger.error("error converting float: #{inspect(e)} v: #{inspect(v)} '#{s}'")
      0.0
    end
  end

  defp decode_measurement(line) do
    case line |> String.trim |> String.split(",", [trim: true]) do
      ["T:" <> t, "P:" <> p, "H:" <> h] ->
        %Measurement{
          temperature: convert_float(t),
          pressure: convert_float(p),
          humidity: convert_float(h)
        }
      _ -> { :error, "Measurement failed" }
    end
  end
end
