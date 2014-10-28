defmodule ExCitp.CitpProtocol do
  @behaviour :ranch_protocol
  require Logger

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, transport, _opts) do
    Logger.debug "Initializing citp_protocol listener"
    :ok = :ranch.accept_ack(ref)
    loop(socket, transport)
  end

  def loop(socket, transport) do
    case transport.recv(socket, 0, 5000) do
      {:ok, data} ->
        transport.send(socket, data)
        loop(socket, transport)
      {:error, :timeout} ->
        loop(socket, transport)
      {:error, :closed} ->
        Logger.debug "Closing socket"
        :ok
      other ->
        Logger.debug "Got unexpected ranch data: #{inspect other}"
        :ok = transport.close(socket)
    end
  end
end
