defmodule Grizzly.Transports.UDP do
  @moduledoc """
  Grizzly transport implementation for UDP
  """
  @behaviour Grizzly.Transport

  alias Grizzly.{Transport, ZWave}

  @impl Grizzly.Transport
  def open(args) do
    priv = Enum.into(args, %{})

    case :gen_udp.open(4000, [:binary, {:active, true}, :inet6]) do
      {:ok, socket} ->
        {:ok, Transport.new(__MODULE__, Map.put(priv, :socket, socket))}

      error ->
        error
    end
  end

  @impl Grizzly.Transport
  def send(transport, binary) do
    host = Transport.assign(transport, :ip_address)
    port = Transport.assign(transport, :port)

    transport
    |> Transport.assign(:socket)
    |> :gen_udp.send(host, port, binary)
  end

  @impl Grizzly.Transport
  def parse_response({:udp, _, _, _, binary}) do
    case ZWave.from_binary(binary) do
      {:ok, _zip_packet} = result -> result
    end
  end

  @impl Grizzly.Transport
  def close(transport) do
    transport
    |> Transport.assign(:socket)
    |> :gen_udp.close()
  end
end
