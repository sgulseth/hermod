defmodule Hermod.StatsHandler do
  require Poison
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def get_stats() do
    GenServer.call(__MODULE__, { :get_stats })
  end

  def client_connect() do
    GenServer.call(__MODULE__, { :client_connect })
  end

  def client_disconnect(reason) do
    GenServer.call(__MODULE__, { :client_disconnect, reason })
  end

  def increment_channel_clients(channel) do
    GenServer.call(__MODULE__, { :increment_channel_clients, channel })
  end

  def decrement_channel_clients(channel) do
    GenServer.call(__MODULE__, { :decrement_channel_clients, channel })
  end

  def increment_messages(channel) do
    GenServer.call(__MODULE__, { :increment_messages, channel })
  end

  ## Callbacks

  def init(:ok) do
    state = %{
      clients: 0,
      connects: 0,
      disconnects: 0,
      messages: 0,
      channels: %{}
    }
    {:ok, state}
  end

  def handle_call({ :get_stats }, {pid, _}, state) do
    stats = Poison.encode!(state)
    send pid, stats
    { :reply, :ok, state }
  end

  def handle_call({ :client_connect }, {_, _}, %{ clients: clients, connects: connects } = state) do
    clients = clients + 1
    connects = connects + 1

    { :reply, :ok, %{ state | clients: clients, connects: connects } }
  end

  def handle_call({ :client_disconnect, _reason }, {_, _}, %{ clients: clients, disconnects: disconnects } = state) do
    clients = clients - 1
    disconnects = disconnects + 1

    { :reply, :ok, %{ state | clients: clients, disconnects: disconnects } }
  end

  def handle_call({ :increment_channel_clients, channel }, {_, _}, %{ channels: channels } = state) do
    channelState = Map.get(channels, channel, Map.new(%{ clients: 0, messages: 0, time: DateTime.to_string(DateTime.utc_now()) }))

    clients = Map.get(channelState, :clients, 0) + 1
    channelState = Map.put(channelState, :clients, clients)

    channels = Map.put(channels, channel, channelState)

    { :reply, :ok, %{ state | channels: channels } }
  end

  def handle_call({ :decrement_channel_clients, channel }, {_, _}, %{ channels: channels } = state) do
    channelState = Map.get(channels, channel, Map.new())

    clients = Map.get(channelState, "clients", 0) - 1
    channelState = Map.put(channelState, "clients", clients)

    channels = if(clients < 1, do: Map.delete(channels, channel), else: Map.put(channels, channel, channelState))

    { :reply, :ok, %{ state | channels: channels } }
  end

  def handle_call({ :increment_messages, channel }, {_, _}, %{ messages: messages, channels: channels } = state) do
    messages = messages + 1

    channelState = Map.get(channels, channel, nil)
    channelState = if(channelState != nil, do: (
      Map.put(channelState, :messages, Map.get(channelState, :messages, 0) + 1)
    ), else: channelState)

    channels = if(channelState != nil, do: Map.put(channels, channel, channelState), else: channels)

    { :reply, :ok, %{ state | messages: messages, channels: channels } }
  end
end
