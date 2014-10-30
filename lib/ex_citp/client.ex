defmodule ExCitp.Client do
  use GenServer
  require Logger

  defmodule State do
    defstruct udp_socket: nil, telnet_socket: nil
  end
  
  # Public API

  def start do
    GenServer.start_link(__MODULE__, [])
  end

  # GenServer Implementation

  def init(_args) do
    {:ok, socket} = :gen_udp.open(Citp.multicast_port,
                                  [:binary, {:active, true},
                                    {:broadcast, true},
                                    {:reuseaddr, true},
                                    {:multicast_loop, false},
                                    # {:ip, Citp.multicast_ip},
                                    {:add_membership, {Citp.multicast_ip, {0, 0, 0, 0}}}
                                  ])
    ExCitp.Utilities.multicast_subscribe(socket)

    {:ok, %State{udp_socket: socket}}
  end

  def handle_info(msg, state) do
    Logger.debug "Client: got info msg: #{inspect msg}"
    {:noreply, state}
  end
end
