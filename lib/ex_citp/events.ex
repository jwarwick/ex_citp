defmodule ExCitp.Events do
  @event_name :citp_events

  def start_link(), do: start_link([])
  def start_link(_args) do
    GenEvent.start_link(name: @event_name)
  end

  def subscribe(handler), do: subscribe(handler, [])
  def subscribe(handler, args) do
    GenEvent.add_handler(@event_name, handler, args)
  end

  def unsubscribe(handler), do: unsubscribe(handler, [])
  def unsubscribe(handler, args) do
    GenEvent.delete_handler(@event_name, handler, args)
  end

  def send_event(msg) do
    GenEvent.notify(@event_name, {:citp_event, msg})
  end

end
