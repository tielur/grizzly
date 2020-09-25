defmodule Grizzly.Transport do
  @moduledoc """
  Behaviour and functions for communicating to `zipgateway`

  """

  alias Grizzly.ZWave.{Command, DecodeError}

  @opaque t() :: %__MODULE__{impl: module(), assigns: map()}

  @type socket() :: :ssl.sslsocket() | :inet.socket()

  @type args() :: [
          ip_address: :inet.ip_address(),
          port: :inet.port_number()
        ]

  @enforce_keys [:impl]
  defstruct assigns: %{}, impl: nil

  @callback open(keyword()) :: {:ok, t()} | {:error, :timeout}

  @callback send(t(), binary()) :: :ok

  @callback parse_response(any()) ::
              {:ok, Command.t()} | {:error, DecodeError.t()}

  @callback close(t()) :: :ok

  @doc """
  Make a new `Grizzly.Transport`

  If need to optionally assign some priv data you can map that into this function.
  """
  @spec new(module(), map()) :: t()
  def new(impl, assigns \\ %{}) do
    %__MODULE__{
      impl: impl,
      assigns: assigns
    }
  end

  @doc """
  Update the assigns with this field and value
  """
  @spec assigns(t(), atom(), any()) :: t()
  def assigns(transport, assign, assign_value),
    do: Map.put(transport.assigns, assign, assign_value)

  @doc """
  Get the assign value for the field
  """
  @spec assign(t(), atom(), any()) :: any()
  def assign(transport, assign, default \\ nil),
    do: Map.get(transport.assigns, assign, default)

  @doc """
  Open the transport
  """
  @spec open(module(), args()) :: {:ok, t()} | {:error, :timeout}
  def open(transport_module, args) do
    transport_module.open(args)
  end

  @doc """
  Send binary data using a transport
  """
  @spec send(t(), binary()) :: :ok
  def send(transport, binary) do
    %__MODULE__{impl: transport_impl} = transport

    transport_impl.send(transport, binary)
  end

  @doc """
  Parse the response for the transport
  """
  @spec parse_response(t(), any()) :: {:ok, Command.t()} | {:error, DecodeError.t()}
  def parse_response(transport, response) do
    %__MODULE__{impl: transport_impl} = transport

    transport_impl.parse_response(response)
  end
end
