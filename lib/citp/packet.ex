defmodule Citp.Packet do
  require Logger

  @ver_major   1
  @ver_minor   0

  @citp_cookie "CITP"
  @pinf_cookie "PINF"
  @ploc_cookie "PLoc"

  defmacro header(sequence, message_size, msg_part_count, msg_part_index, content_type) do
    quote do
      << @citp_cookie,
      @ver_major, @ver_minor,
      unquote(sequence) :: size(16)-little,
      unquote(message_size) :: size(32)-little,
      unquote(msg_part_count) :: size(16)-little,
      unquote(msg_part_index) :: size(16)-little,
      unquote(content_type) :: size(32)-binary
      >>
    end
  end

  
  def complete_packet(data = header(_sequence, size, _msg_count, _part, _type) <> <<rest>>) do
    Logger.debug "Complete pkt: investigating #{inspect data}"
    unless byte_size(data) >= size, do: false
    packet = binary_part(data, 0, size)
    {:ok, packet, <<>>}
  end
  def complete_packet(_) do
    Logger.debug "Complete pkt: doesn't match header"
    false
  end

  def build_header(content_type, content \\ <<>> , sequence \\ 0, msg_part_count \\ 1, msg_part_index \\ 0) do
    message_size = byte_size(content) + 20
    << @citp_cookie,
    @ver_major, @ver_minor,
    sequence :: size(16)-little,
    message_size :: size(32)-little,
    msg_part_count :: size(16)-little,
    msg_part_index :: size(16)-little,
    content_type :: binary,
    content :: binary
    >>
  end

  def build_pinf(content_type, content \\ <<>>) do
    build_header(@pinf_cookie, 
    << content_type :: binary,
    content :: binary
    >>)
  end

  def build_ploc(listening_port \\ 0, type \\ "Visualizer", name \\ "Default Name", state \\ "Running") do
    build_pinf(@ploc_cookie,
    << listening_port :: size(16)-little,
    type :: binary, 0,
    name :: binary, 0,
    state :: binary, 0
    >>)
  end

end
