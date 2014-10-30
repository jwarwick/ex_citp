defmodule ExCitp.Utilities do
  require Logger

  def multicast_subscribe(socket) do
    {:ok, if_list} = :inet.getif()
    Enum.each(if_list, &(multicast_subscribe(socket, &1)))
  end

  def multicast_subscribe(socket, {{127, 0, 0, 1}, _broadcast, _subnet}), do: :ok
  def multicast_subscribe(socket, {ip_address, _broadcast, _subnet}) do
    :ok = :inet.setopts(socket, [{:add_membership, {Citp.multicast_ip, ip_address}}])
    Logger.debug "Subscribing interface to multicast: #{inspect ip_address}"
  end
end
