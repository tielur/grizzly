defmodule Grizzly.ZWave.Commands.RssiReport do
  @moduledoc """
  This command is used to advertise the measured RSSI on the Z-Wave network for each used channel.

  Params:

    * `:channels` - Each carries the measured RSSI value for the channel

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @type param :: {:channels, [NetworkManagementInstallationMaintenance.rssi()]}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :rssi_report,
      command_byte: 0x08,
      command_class: NetworkManagementInstallationMaintenance,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    channels = Command.param!(command, :channels)

    for channel <- channels,
        into: <<>>,
        do: <<NetworkManagementInstallationMaintenance.rssi_to_byte(channel)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(binary) do
    channel_bytes = :erlang.binary_to_list(binary)

    result =
      Enum.reduce_while(channel_bytes, {:ok, []}, fn channel_byte, {:ok, acc} ->
        case NetworkManagementInstallationMaintenance.rssi_from_byte(channel_byte) do
          {:ok, channel} ->
            {:cont, {:ok, acc ++ [channel]}}

          {:error, %DecodeError{} = decode_error} ->
            {:halt,
             {:error, %DecodeError{decode_error | param: :channels, command: :rssi_report}}}
        end
      end)

    case result do
      {:ok, channels} ->
        {:ok, [channels: channels]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
