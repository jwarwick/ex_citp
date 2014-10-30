defmodule ExCitp.CitpProtocol do
  @behaviour :ranch_protocol
  require Logger

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, transport, _opts) do
    # Logger.debug "Initializing citp_protocol listener"
    {:ok, net} = transport.peername(socket)
    Logger.info "Accepted connection from #{inspect net}"
    :ok = :ranch.accept_ack(ref)
    pname = Citp.Packet.build_pnam("ExCitp Server")
    transport.send(socket, pname)
    loop(socket, transport, <<>>)
  end

  defp loop(socket, transport, buffer) do
    case transport.recv(socket, 0, 5000) do
      {:ok, data} ->
        # Logger.debug "Got telnet data: #{inspect data}"
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
    # Logger.debug "CitpProtocol: Got a packet: #{inspect packet}"
    handle_result(Citp.Packet.parse(packet))
  end

  defp handle_result({:ok, result}) do
    Logger.debug "CitpProtocol: parse packet #{inspect result}"
    ExCitp.Events.send_event(result)
  end
  defp handle_result(result) do
    Logger.debug "CitpProtocol: unknown packet #{inspect result}"
  end

end
