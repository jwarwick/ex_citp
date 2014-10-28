defmodule ExCitp.Listener do
  use GenServer
  require Logger

  @local_name TcpListener

  # Public API

  def start_link, do: start_link(%{})
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @local_name)
  end

  def get_listening_port do
    GenServer.call(@local_name, :get_listening_port) 
  end

  # Callback Implementation

  def init(_args) do
    {:ok, _pid} = :ranch.start_listener(:citp_listener, 1, :ranch_tcp,
                                        [], ExCitp.CitpProtocol, [])
    port = :ranch.get_port(:citp_listener)
    Logger.debug "Ranch listening on port #{port}"
    {:ok, %{port: port}}
  end

  def handle_call(:get_listening_port, _from, state) do
    {:reply, state.port, state}
  end
end
