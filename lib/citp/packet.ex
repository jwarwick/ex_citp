defmodule Citp.Packet do
  require Logger

  @ver_major   1
  @ver_minor   0

  @citp_cookie "CITP"

  @pinf_cookie "PINF"
  @pnam_cookie "PNam"
  @ploc_cookie "PLoc"

  @sdmx_cookie "SDMX"
  @unam_cookie "UNam"
  @chbk_cookie "ChBk"

  defmacro header(sequence, message_size, msg_part_count, msg_part_index, content_type) do
    quote do
      << @citp_cookie,
      @ver_major, @ver_minor,
      unquote(sequence) :: size(16)-little,
      unquote(message_size) :: size(32)-little,
      unquote(msg_part_count) :: size(16)-little,
      unquote(msg_part_index) :: size(16)-little,
      unquote(content_type) :: size(32)-little
      >>
    end
  end

  defmacro pinf(content_type) do
    quote do
      <<unquote(content_type)::size(32)-little>>
    end
  end

  defmacro pnam(name) do
    quote do
      <<unquote(name)::binary>>
    end
  end

  defmacro ploc(port, data) do
    quote do
      <<unquote(port)::size(16)-little, unquote(data)::binary>>
    end
  end

  defmacro sdmx(content_type) do
    quote do
      <<unquote(content_type)::size(32)-little>>
    end
  end

  defmacro unam(index, name) do
    quote do
      <<unquote(index), unquote(name)::binary>>
    end
  end

  defmacro chbk(blind, index, first_channel, count, levels) do
    quote do
      <<unquote(blind), unquote(index), unquote(first_channel)::size(16)-little,
        unquote(count)::size(16)-little, unquote(levels)::binary>>
    end
  end

  
  def complete_packet(data = header(_sequence, size, _msg_count, _part, _type) <> <<_rest::binary>>) do
    # Logger.debug "Complete pkt: investigating #{inspect data}"
    unless byte_size(data) >= size, do: false
    packet = binary_part(data, 0, size)
    {:ok, packet, <<>>}
  end
  def complete_packet(_) do
    # Logger.debug "Complete pkt: doesn't match header"
    false
  end

  def parse(header(_sequence, _size, _msg_count, _part, type) <> <<rest::binary>>) do
    parse_layer(<<type::size(32)-little>>, rest)
  end
  def parse(data) do
    {:error, {:invalid_packet, %{data: data}}}
  end

  defp parse_layer(@pinf_cookie, pinf(type) <> <<rest::binary>>) do
    parse_message(<<type::size(32)-little>>, rest)
  end
  defp parse_layer(@sdmx_cookie, sdmx(type) <> <<rest::binary>>) do
    parse_message(<<type::size(32)-little>>, rest)
  end

  defp parse_message(@pnam_cookie, pnam(name)) do
    stripped_name = String.rstrip(name, 0)
    {:ok, {:peer_name, %{name: stripped_name}}}
  end
  defp parse_message(@ploc_cookie, ploc(port, data)) do
    [type, name, state] = String.split(data, <<0>>, trim: true)
    {:ok, {:peer_location, %{listening_port: port, type: type, name: name, state: state}}}
  end
  defp parse_message(@unam_cookie, unam(index, name)) do
    stripped_name = String.rstrip(name, 0)
    {:ok, {:universe_name, %{universe_index: index, name: stripped_name}}}
  end
  defp parse_message(@chbk_cookie, chbk(blind, index, first, count, levels)) do
    blind = case blind do
      1 -> true
      _ -> false
    end
    levels = :binary.bin_to_list(levels)
    {:ok, {:channel_block, 
        %{blind: blind, universe_index: index, first_channel: first, 
          channel_count: count, levels: levels}}}
  end
  defp parse_message(type, data) do
    {:error, {:unknown_type, %{type: type, data: data}}}
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

  def build_pnam(name) do
    peer_name = pnam(name)
    <<cookie::size(32)-little>> = <<@pnam_cookie>>
    pinf_layer = pinf(cookie)
    msg_size = byte_size(peer_name) + byte_size(pinf_layer) + 20
    <<cookie::size(32)-little>> = <<@pinf_cookie>>
    header_layer = header(0, msg_size, 1, 0, cookie)
    [header_layer, pinf_layer, peer_name]
  end

end
