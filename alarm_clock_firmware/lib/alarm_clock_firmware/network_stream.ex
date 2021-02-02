defmodule AlarmClockFirmware.NetworkStream do
  use GenServer

  alias AlarmClockFirmware.Button
  alias AlarmClockFirmware.Led

  require Logger

  @recordings_dir :alarm_clock_firmware
                  |> Application.compile_env!(__MODULE__)
                  |> Keyword.fetch!(:recordings_dir)

  @enforce_keys [:kill, :vlc]
  defstruct close: false, from: nil, kill: nil, line: [], port: nil, url: nil, vlc: nil

  @opaque t :: %__MODULE__{
            close: boolean(),
            from: GenServer.from() | nil,
            kill: String.t(),
            line: [String.t()],
            port: port(),
            url: String.t(),
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
    GenServer.cast(__MODULE__, :close)
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
      nil -> {:stop, {:error, :missing_vlc_or_kill}}
      error -> {:stop, error}
    end
  end

  @impl GenServer
  def handle_call({:open, url, duration, async}, from, %__MODULE__{port: nil} = state) do
    Led.on()

    updated_state = open_vlc(url, state)

    if is_integer(duration) do
      Process.send_after(self(), :close, duration)
    end

    case async do
      true -> {:reply, :ok, updated_state}
      false -> {:noreply, %__MODULE__{updated_state | from: from}}
    end
  end

  @impl GenServer
  def handle_cast(:close, state) do
    close(state)
  end

  @impl GenServer
  def handle_info(:close, state) do
    close(state)
  end

  def handle_info({Button, :pressed}, state) do
    close(state)
  end

  def handle_info({Button, :released}, state) do
    {:noreply, state}
  end

  def handle_info(
        {port, {:data, {:noeol, next_part}}},
        %__MODULE__{line: parts, port: port} = state
      ) do
    {:noreply, %__MODULE__{state | line: [parts | next_part]}}
  end

  def handle_info({port, {:data, {:eol, ""}}}, %__MODULE__{line: [], port: port} = state) do
    # Ignore empty lines
    {:noreply, state}
  end

  def handle_info(
        {port, {:data, {:eol, last_part}}},
        %__MODULE__{close: close, line: parts, port: port} = state
      ) do
    Logger.debug([parts | last_part])

    updated_state = %__MODULE__{state | line: []}

    if !close and last_part =~ "nothing to play" do
      close(updated_state, false)
    else
      {:noreply, updated_state}
    end
  end

  def handle_info(
        {:EXIT, port, reason},
        %__MODULE__{close: close, from: from, port: port, url: url} = state
      ) do
    case close do
      true ->
        Led.off()

        case reason do
          :normal -> from && GenServer.reply(from, :ok)
          not_normal -> from && GenServer.reply(from, {:error, not_normal})
        end

        {:noreply, %__MODULE__{state | close: false, port: nil}}

      false ->
        Logger.warn("VLC exited unexpectedly.  Restarting.")
        {:noreply, %__MODULE__{open_vlc(url, state) | close: false}}
    end
  end

  def handle_info({:EXIT, _port, :normal}, state) do
    # Probably the call to kill
    {:noreply, state}
  end

  @impl GenServer
  def terminate(reason, %{from: from} = state) do
    from && GenServer.reply(from, {:error, {:exit, reason}})
    close(state)
  end

  defp open_vlc(url, %__MODULE__{vlc: vlc} = state) do
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
        {:line, 64}
      ])

    %__MODULE__{state | port: port, url: url}
  end

  defp close(%__MODULE__{kill: kill, port: port} = state, expected \\ true) do
    case Port.info(port, :os_pid) do
      {:os_pid, os_pid} ->
        System.cmd(kill, [to_string(os_pid)])
        {:noreply, %__MODULE__{state | close: expected}}

      nil ->
        {:noreply, %__MODULE__{state | close: expected, port: nil}}
    end
  end
end
