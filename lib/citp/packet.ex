defmodule Citp.Packet do
  @ver_major   1
  @ver_minor   0

  @citp_cookie "CITP"
  @pinf_cookie "PINF"
  @ploc_cookie "PLoc"


  def header(content_type, content \\ <<>> , sequence \\ 0, msg_part_count \\ 1, msg_part_index \\ 0) do
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

  def pinf(content_type, content \\ <<>>) do
    header(@pinf_cookie, 
    << content_type :: binary,
    content :: binary
    >>)
  end

  def ploc(listening_port \\ 0, type \\ "Visualizer", name \\ "Default Name", state \\ "Running") do
    pinf(@ploc_cookie,
    << listening_port :: size(16)-little,
    type :: binary, 0,
    name :: binary, 0,
    state :: binary, 0
    >>)
  end

end
