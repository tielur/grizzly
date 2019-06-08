defmodule Grizzly.CommandClass.Battery.Get.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Battery.Get

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %Get{}} == Get.init([])
    end

    test "encodes correctly" do
      {:ok, command} = Get.init(seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x80, 0x02>>

      assert {:ok, binary} == Get.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = Get.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack respones" do
      {:ok, command} = Get.init(seq_number: 0x07, retries: 0)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == Get.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = Get.init(seq_number: 0x07)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:retry, %Get{}} = Get.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = Get.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = Get.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = Get.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = Get.handle_response(command, packet)
    end

    test "handles battery report responses" do
      report = %{command_class: :battery, command: :report, value: 80}
      packet = Packet.new(body: report)
      {:ok, command} = Get.init([])

      assert {:done, {:ok, 80}} == Get.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = Get.init([])
      assert {:continue, %Get{}} = Get.handle_response(command, %{command_class: :foo})
    end
  end
end
