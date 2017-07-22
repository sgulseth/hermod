defmodule Hermod.RedisHandler do
  require Logger
  use GenServer

  @prefix Hermod.Settings.prefix

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def subscribe(channel) do
    GenServer.call(__MODULE__, {:subscribe, channel})
  end

  def unsubscribe(channel) do
    GenServer.call(__MODULE__, {:unsubscribe, channel})
  end

  def cleanup() do
    GenServer.call(__MODULE__, {:cleanup})
  end

  ## Callbacks

  def init(:ok) do
    {:ok, conn} = Redix.PubSub.start_link(host: Hermod.Settings.redis_host, port: Hermod.Settings.redis_port)

    Logger.info "Connected to redis"

    {:ok, %{conn: conn, channels: %{}}}
  end

  def check do
    GenServer.call(__MODULE__, {:check})
  end

  def handle_call({ :check }, {_, _}, _) do
    {:reply, :ok, :ok}
  end

  def handle_call({:subscribe, channel}, {pid, _}, %{ conn: conn } = state) do
    { :ok, new_channel, state } = add_pid_to_channel(pid, channel, state)

    if new_channel do
      :ok = Redix.PubSub.subscribe(conn, "#{@prefix}:#{channel}", self())
    end

    { :reply, :ok, state }
  end

  def handle_call({:unsubscribe, channel}, {pid, _}, %{conn: conn} = state) do
    { :ok, empty_channel, state } = delete_pid_from_channel(pid, channel, state)

    if empty_channel do
      :ok = Redix.PubSub.unsubscribe(conn, "#{@prefix}:#{channel}", self())
    end

    { :reply, :ok, state }
  end

  def handle_call({ :cleanup }, {pid, _}, %{conn: conn} = state) do
    { :ok, empty_channels, state } = cleanup_pid(pid, state)

    # Unsubscribe from all the empty channels
    # TODO: Not implemented in cleanup_pid
    for channel <- empty_channels do
      Redix.PubSub.unsubscribe(conn, channel, self())
    end

    { :reply, :ok, state }
  end

  def handle_info({:redix_pubsub, _, :message, %{channel: "#{@prefix}:" <> channel, payload: message}}, %{channels: channels} = state) do
    pubSubTopicClients = Map.get(channels, channel, MapSet.new)
    for pid <- pubSubTopicClients, do: send pid, message

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Websocket client helper
  def add_pid_to_channel(pid, channel, %{channels: channels} = state) do
    new_channel = Map.has_key?(channels, channel) == false
    channelPids = Map.get(channels, channel, MapSet.new)

    channels = if(MapSet.member?(channelPids, pid) == false, do: Map.put(channels, channel, MapSet.put(channelPids, pid)), else: channels)

    Logger.debug "subscribing process to #{channel}"
    Hermod.StatsHandler.increment_channel_clients(channel)

    { :ok, new_channel, %{state | channels: channels} }
  end

  def delete_pid_from_channel(pid, channel, %{channels: channels} = state) do
    channelPids = Map.get(channels, channel, MapSet.new)
    channels = Map.put(channels, channel, MapSet.delete(channelPids, pid))

    empty_channel = MapSet.size(Map.get(channels, channel, MapSet.new)) == 0

    Logger.debug "unsubscribing process to #{channel}"
    Hermod.StatsHandler.decrement_channel_clients(channel)

    { :ok, empty_channel, %{state | channels: channels} }
  end

  def cleanup_pid(pid, %{channels: channels} = state) do
    empty_channels = MapSet.new
    # Loop over each channel and remove the pid
    channels = Enum.reduce Map.keys(channels), %{}, fn channel, map ->
      pids = MapSet.delete(Map.get(channels, channel), pid)
      if MapSet.size(pids) > 0 do
        Map.put(map, channel, pids)
      end

      map
    end

    { :ok, empty_channels, %{state | channels: channels} }
  end
end
