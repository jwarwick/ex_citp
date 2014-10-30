defmodule ExCitp.Logger do
  use GenEvent
  require Logger

  def start_logger do
    pid = {ExCitp.Logger, make_ref}
    :ok = ExCitp.Events.subscribe(pid)
    {:ok, pid}
  end

  def stop_logger(pid) do
    ExCitp.Events.unsubscribe(pid)
  end

  def handle_event(event, state) do
    Logger.info "CITP Event: #{inspect event}"
    {:ok, state}
  end
end
