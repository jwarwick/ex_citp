defmodule ExCitp.PeerLocator do
  use GenServer
  require Logger

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
    {:ok, socket} = :gen_udp.open(0, #Citp.multicast_port,
                                  [:binary, {:active, true},
                                    {:broadcast, true},
                                    {:reuseaddr, true},
                                    {:multicast_loop, true},
                                    {:add_membership, {Citp.multicast_ip, {0, 0, 0, 0}}}
                                  ])
    ExCitp.Utilities.multicast_subscribe(socket)

    listening_port = ExCitp.Listener.get_listening_port()
    Logger.debug "PeerLocator - tcp listener on port #{listening_port}"

    state = %State{listening_port: listening_port, socket: socket} 
    send_location_message(state)
    
    ref = start_timer
    {:ok, %State{state | timer_ref: ref}}
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
    # Logger.debug "Sending location message"
    packet = Citp.Packet.build_ploc(state.listening_port)
    :ok = :gen_udp.send(state.socket, Citp.multicast_ip, Citp.multicast_port, packet)
  end

end
