defmodule ExCitp.CitpProtocol do
  @behaviour :ranch_protocol
  require Logger

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, transport, _opts) do
    Logger.debug "Initializing citp_protocol listener"
    {:ok, net} = transport.peername(socket)
    Logger.info "Accepted connection from #{inspect net}"
    :ok = :ranch.accept_ack(ref)
    loop(socket, transport, <<>>)
  end

  defp loop(socket, transport, buffer) do
    case transport.recv(socket, 0, 5000) do
      {:ok, data} ->
        Logger.debug "Got telnet data: #{inspect data}"
        # transport.send(socket, data)
        new_buffer = handle_data(data, buffer)
        loop(socket, transport, new_buffer)
      {:error, :timeout} ->
        loop(socket, transport, buffer)
      {:error, :closed} ->
        Logger.debug "Closing socket"
        :ok
      other ->
        Logger.debug "Got unexpected ranch data: #{inspect other}"
        :ok = transport.close(socket)
    end
  end

  defp handle_data(data, buffer) do
    total_data = data <> buffer
    case Citp.Packet.complete_packet(total_data) do
      {:ok, packet, rest} -> handle_packet(packet)
                       rest
      _ -> total_data
    end
  end


  defp handle_packet(packet) do
    IO.puts "Got a packet: #{inspect packet}"
  end
  

end
