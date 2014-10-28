defmodule ExCitp.PeerLocator do
  use GenServer
  require Logger

  @multicast_port       4809
  @multicast_ip         {224, 0, 0, 180}
  @broadcast_timeout_ms 2000

  defmodule ExCitp.PeerLocator.State do
    defstruct listening_port: nil, socket: nil, timer_ref: nil
  end
  alias ExCitp.PeerLocator.State

  # Public API

  def start_link, do: start_link(%{})
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  # Callback Implementation

  def init(_args) do
    {:ok, socket} = :gen_udp.open(@multicast_port, 
                                  [:binary, {:active, :true},
                                   {:multicast_loop, :false},
                                   {:ip, @multicast_ip},
                                   {:add_membership, {@multicast_ip, {0, 0, 0, 0}}}])
    listening_port = 16 #ExCitp.Listener.get_listening_port
    Logger.debug "PeerLocator - tcp listener on port #{listening_port}"
    ref = start_timer
    {:ok, %State{listening_port: listening_port, socket: socket, timer_ref: ref}}
  end

  def handle_info({:timeout, _ref, :send_peer_info}, state) do
    Logger.debug "Sending PLoc message"
    ref = start_timer
    {:noreply, %State{state | timer_ref: ref}}
  end
  def handle_info(msg, state) do
    Logger.debug "PeerLocator.handle_info got msg #{inspect msg}"
    {:noreply, state}
  end

  # Private functions

  defp start_timer do
    :erlang.start_timer(@broadcast_timeout_ms, self(), :send_peer_info)
  end

end
