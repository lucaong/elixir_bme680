defmodule Bme680 do
  @moduledoc """
  `elixir_bme680` provides a high level abstraction to interface with the
  BME680 environmental sensor on Linux platforms.
  """
  use Bitwise
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct port: nil, subscribers: [], async_subscribers: [], measuring: false
  end

  defmodule Measurement do
    @moduledoc false
    defstruct temperature: nil, pressure: nil, humidity: nil, gas_resistance: nil
  end


  @doc """
  Starts and links the `Bme680` GenServer.
  """
  @spec start_link([ i2c_device_number: integer, i2c_address: 0x76 | 0x77 ], [ term ]) :: GenServer.on_start()
  def start_link(bme_opts \\ [], opts \\ []) do
    i2c_device_number = Keyword.get(bme_opts, :i2c_device_number, 1)
    i2c_address = Keyword.get(bme_opts, :i2c_address, 0x76)

    if Enum.member?([0x76, 0x77], i2c_address) do
      arg = [i2c_device_number, i2c_address]
      GenServer.start_link(__MODULE__, arg, opts)
    else
      { :error, "invalid i2c address #{i2c_address}. Valid values are 0x76 and 0x77" }
    end
  end

  @doc """
  Perform a measurement on the BME680 sensor and synchronously return it

  Measurements are structs like:
  ```
  %Bme680.Measurement{
    temperature: 21.74,
    pressure: 1090.52,
    humidity: 45.32,
    gas_resistance: 10235
  }
  ```
  """
  @spec measure(GenServer.server()) :: %Measurement{ temperature: float, pressure: float, humidity: float, gas_resistance: integer | nil }
  def measure(pid) do
    GenServer.call(pid, :measure)
  end

  @doc """
  Perform a measurement on the BME680 sensor and asynchronously send the result
  as a message to the pid in `send_to`
  """
  @spec measure_async(GenServer.server(), pid) :: :ok
  def measure_async(pid, send_to) do
    GenServer.cast(pid, {:measure_async, send_to})
  end

  @doc """
  Gracefully stops the `Bme680` GenServer.
  """
  @spec stop(GenServer.server()) :: :ok
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  # GenServer callbacks

  def init([i2c_device_number, i2c_address]) do
    executable_dir = Application.get_env(:elixir_bme680, :executable_dir, :code.priv_dir(:elixir_bme680))

    port = Port.open({:spawn_executable, executable_dir ++ '/bme680'}, [
      {:args, ["#{i2c_device_number}", "#{i2c_address}"]},
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

  defp decode_measurement(line) do
    case line |> String.trim |> String.split(",", [trim: true]) do
      ["T:" <> t, "P:" <> p, "H:" <> h, "G:" <> g] ->
        %Measurement{
          temperature: String.to_float(t),
          pressure: String.to_float(p),
          humidity: String.to_float(h),
          gas_resistance: String.to_integer(g)
        }
      ["T:" <> t, "P:" <> p, "H:" <> h] ->
        %Measurement{
          temperature: String.to_float(t),
          pressure: String.to_float(p),
          humidity: String.to_float(h)
        }
      _ -> { :error, "Measurement failed" }
    end
  end
end
