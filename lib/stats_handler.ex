defmodule Hermod.StatsHandler do
  require Poison
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def get_stats() do
    GenServer.call(__MODULE__, { :get_stats })
  end

  def increment_clients() do
    GenServer.call(__MODULE__, { :increment_clients })
  end

  def decrement_clients() do
    GenServer.call(__MODULE__, { :decrement_clients })
  end

  def increment_channel_clients(channel) do
    GenServer.call(__MODULE__, { :increment_channel_clients, channel })
  end

  def decrement_channel_clients(channel) do
    GenServer.call(__MODULE__, { :decrement_channel_clients, channel })
  end

  ## Callbacks

  def init(:ok) do
    state = %{
      clients: 0,
      open_channels: %{}
    }
    {:ok, state}
  end

  def handle_call({ :get_stats }, {pid, _}, state) do
    stats = Poison.encode!(state)
    send pid, stats
    { :reply, :ok, state }
  end

  def handle_call({ :increment_clients }, {_, _}, %{ clients: clients } = state) do
    clients = clients + 1

    { :reply, :ok, %{ state | clients: clients } }
  end

  def handle_call({ :decrement_clients }, {_, _}, %{ clients: clients } = state) do
    clients = clients - 1

    { :reply, :ok, %{ state | clients: clients } }
  end

  def handle_call({ :increment_channel_clients, channel }, {_, _}, %{ open_channels: open_channels } = state) do
    channelState = Map.get(open_channels, channel, Map.new(%{ clients: 0, time: DateTime.to_string(DateTime.utc_now()) }))

    clients = Map.get(channelState, :clients, 0) + 1
    channelState = Map.put(channelState, :clients, clients)

    open_channels = Map.put(open_channels, channel, channelState)

    { :reply, :ok, %{ state | open_channels: open_channels } }
  end

  def handle_call({ :decrement_channel_clients, channel }, {_, _}, %{ open_channels: open_channels } = state) do
    channelState = Map.get(open_channels, channel, Map.new(%{ clients: 0, time: DateTime.to_string(DateTime.utc_now()) }))

    clients = Map.get(channelState, "clients", 0) - 1
    channelState = Map.put(channelState, "clients", clients)

    open_channels = if(clients < 1, do: Map.delete(open_channels, channel), else: Map.put(open_channels, channel, channelState))

    { :reply, :ok, %{ state | open_channels: open_channels } }
  end
end
