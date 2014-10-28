defmodule ExCitp.PeerLocator do
  use GenServer
  require Logger

  @multicast_port       4809
  @multicast_ip         {224, 0, 0, 180}
  @broadcast_timeout_ms 2000

  defmodule State do
    defstruct listening_port: nil, socket: nil, timer_ref: nil
  end

  # Public API

  def start_link, do: start_link(%{})
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  # Callback Implementation

  def init(_args) do
    {:ok, socket} = :gen_udp.open(@multicast_port, 
                                  [:binary, {:active, true},
                                    {:broadcast, true},
                                    {:reuseaddr, true},
                                    {:multicast_loop, false},
                                    # {:ip, @multicast_ip},
                                    # {:add_membership, {@multicast_ip, {0, 0, 0, 0}}}
                                  ])
    multicast_subscribe(socket)

    listening_port = :ranch.get_port(:citp_listener)
    # listening_port = ExCitp.Listener.get_listening_port()
    Logger.debug "PeerLocator - tcp listener on port #{listening_port}"
    ref = start_timer
    {:ok, %State{listening_port: listening_port, socket: socket, timer_ref: ref}}
  end

  def handle_info({:timeout, _ref, :send_peer_info}, state) do
    send_location_message(state)
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

  defp send_location_message(state = %State{}) do
    packet = Citp.Packet.ploc(state.listening_port)
    :ok = :gen_udp.send(state.socket, @multicast_ip, @multicast_port, packet)
  end

  defp multicast_subscribe(socket) do
    {:ok, if_list} = :inet.getif()
    Enum.each(if_list, &(multicast_subscribe(socket, &1)))
  end

  defp multicast_subscribe(socket, {{127, 0, 0, 1}, _broadcast, _subnet}), do: :ok
  defp multicast_subscribe(socket, {ip_address, _broadcast, _subnet}) do
    :ok = :inet.setopts(socket, [{:add_membership, {@multicast_ip, ip_address}}])
    Logger.debug "Subscribing interface to multicast: #{inspect ip_address}"
  end
end
