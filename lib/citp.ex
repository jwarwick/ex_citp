defmodule Citp do

  @multicast_ip         {224, 0, 0, 180}
  @multicast_port       4809

  def multicast_ip, do: @multicast_ip
  def multicast_port, do: @multicast_port
end
