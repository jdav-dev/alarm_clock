defmodule AlarmClockFirmware.NetworkStream do
  use GenServer

  def open(url, duration \\ :infinity)
      when (is_binary(url) and duration == :infinity) or is_integer(duration) do
    with path when is_binary(path) <- System.find_executable("vlc"),
         {:ok, pid} <- GenServer.start_link(__MODULE__, {path, duration}, name: __MODULE__) do
      GenServer.call(pid, {:open, url}, :infinity)
    else
      nil -> {:error, :vlc_not_found}
      error -> error
    end
  end

  def close do
    GenServer.call(__MODULE__, :close)
  end

  @impl GenServer
  def init({path, duration}) do
    unless duration == :infinity do
      Process.send_after(self(), :close, duration)
    end

    {:ok, %{from: nil, line: [], path: path, port: nil}}
  end

  @impl GenServer
  def handle_call({:open, url}, from, %{from: nil, path: path} = state) do
    timestamp = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(:basic)
    dst = Path.join([".", "recordings", [timestamp, ".mp4"]])

    port =
      Port.open({:spawn_executable, path}, [
        {:args,
         [
           "--intf",
           "rc",
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

    {:noreply, %{state | from: from, port: port}}
  end

  def handle_call(:close, _from, %{from: from, port: port} = state) do
    Port.close(port)
    GenServer.reply(from, :ok)
    {:stop, :normal, :ok, state}
  end

  @impl GenServer
  def handle_info({port, {:data, {:noeol, next_part}}}, %{line: parts, port: port} = state) do
    {:noreply, %{state | line: [parts, next_part]}}
  end

  def handle_info({port, {:data, {:eol, last_part}}}, %{line: parts, port: port} = state) do
    IO.binwrite([parts, last_part, "\n"])
    {:noreply, %{state | line: []}}
  end

  def handle_info({port, {:exit_status, status}}, %{from: from, port: port} = state) do
    GenServer.reply(from, {:error, status})
    {:stop, :normal, state}
  end

  def handle_info(:close, %{from: from, port: port} = state) do
    Port.close(port)
    GenServer.reply(from, :ok)
    {:stop, :normal, state}
  end
end
