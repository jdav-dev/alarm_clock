defmodule AlarmClockFirmware.NetworkStream do
  use GenServer

  alias AlarmClockFirmware.Button
  alias AlarmClockFirmware.Led

  require Logger

  @recordings_dir :alarm_clock_firmware
                  |> Application.compile_env!(__MODULE__)
                  |> Keyword.fetch!(:recordings_dir)

  @enforce_keys [:kill, :vlc]
  defstruct from: nil, kill: nil, line: [], os_pid: nil, port: nil, vlc: nil

  @opaque t :: %__MODULE__{
            from: GenServer.from() | nil,
            kill: String.t(),
            line: [String.t()],
            os_pid: non_neg_integer() | nil,
            port: port(),
            vlc: String.t()
          }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def open(url, opts \\ []) when is_binary(url) and is_list(opts) do
    async = Keyword.get(opts, :async, true)
    duration = opts[:duration] || :infinity

    timeout =
      case async do
        true -> :timer.seconds(5)
        false -> :infinity
      end

    GenServer.call(__MODULE__, {:open, url, duration, async}, timeout)
  end

  def close do
    GenServer.call(__MODULE__, :close)
  end

  @impl GenServer
  def init(_opts) do
    with vlc when is_binary(vlc) <- System.find_executable("vlc"),
         kill when is_binary(kill) <- System.find_executable("kill"),
         :ok <- File.mkdir_p(@recordings_dir),
         :ok <- Button.subscribe() do
      Process.flag(:trap_exit, true)
      {:ok, %__MODULE__{kill: kill, vlc: vlc}}
    else
      nil -> {:error, :missing_vlc_or_kill}
      error -> error
    end
  end

  @impl GenServer
  def handle_call({:open, url, duration, async}, from, %__MODULE__{port: nil, vlc: vlc} = state) do
    Led.on()

    timestamp = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(:basic)
    dst = Path.join(@recordings_dir, [timestamp, ".mp4"])

    port =
      Port.open({:spawn_executable, vlc}, [
        {:args,
         [
           "--intf",
           "dummy",
           "--verbose",
           "2",
           "--playlist-autostart",
           "--play-and-stop",
           url,
           "--sout",
           "#duplicate{dst='std{access=file{no-append,no-format,no-overwrite},mux=mp4,dst=#{dst}}',dst=display}"
         ]},
        {:env, []},
        :stderr_to_stdout,
        :binary,
        {:line, 64},
        :exit_status
      ])

    {:os_pid, os_pid} = Port.info(port, :os_pid)

    if is_integer(duration) do
      Process.send_after(self(), :close, duration)
    end

    case async do
      true -> {:reply, :ok, %__MODULE__{state | os_pid: os_pid, port: port}}
      false -> {:noreply, %__MODULE__{state | from: from, os_pid: os_pid, port: port}}
    end
  end

  def handle_call(:close, _from, state) do
    close(state)
    {:stop, :normal, :ok, state}
  end

  @impl GenServer
  def handle_info(
        {port, {:data, {:noeol, next_part}}},
        %__MODULE__{line: parts, port: port} = state
      ) do
    {:noreply, %__MODULE__{state | line: [parts | next_part]}}
  end

  def handle_info(
        {port, {:data, {:eol, last_part}}},
        %__MODULE__{line: parts, port: port} = state
      ) do
    Logger.debug([parts | last_part])
    {:noreply, %__MODULE__{state | line: []}}
  end

  def handle_info({port, {:exit_status, status}}, %__MODULE__{from: from, port: port} = state) do
    from && GenServer.reply(from, {:error, status})
    {:stop, :normal, state}
  end

  def handle_info(:close, state) do
    close(state)
    {:stop, :normal, state}
  end

  def handle_info({Button, :pressed}, state) do
    handle_info(:close, state)
  end

  def handle_info({Button, :released}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    close(state)
  end

  defp close(%__MODULE__{from: from, kill: kill, os_pid: os_pid, port: port})
       when is_port(port) do
    Led.off()
    Port.close(port)
    System.cmd(kill, [to_string(os_pid)])
    from && GenServer.reply(from, :ok)
  end

  defp close(_state) do
    # No port was open
  end
end
