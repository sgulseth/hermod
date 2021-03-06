defmodule Hermod.RedisHandler do
  require Logger
  use GenServer

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

  def handle_call({:subscribe, channel}, {pid, _}, state) do
    { :ok, state } = add_pid_to_channel(pid, channel, state)

    { :reply, :ok, state }
  end

  def handle_call({:unsubscribe, channel}, {pid, _}, state) do
    { :ok, state } = delete_pid_from_channel(pid, channel, state)

    { :reply, :ok, state }
  end

  def handle_call({ :cleanup }, {pid, _}, state) do
    { :ok, state } = cleanup_pid(pid, state)

    { :reply, :ok, state }
  end

  def handle_info({:redix_pubsub, _, :message, %{channel: channelWithPrefix, payload: message}}, %{channels: channels} = state) do
    [_, channel] = String.split(channelWithPrefix, "#{Hermod.Settings.prefix}:", parts: 2)
    pubSubTopicClients = Map.get(channels, channel, MapSet.new)
    for pid <- pubSubTopicClients, do: send pid, message

    Hermod.StatsHandler.increment_messages(channel)

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Redis helpers

  def redis_subscribe(conn, channel) do
    Redix.PubSub.subscribe(conn, "#{Hermod.Settings.prefix}:#{channel}", self())
  end

  def redis_unsubscribe(conn, channel) do
    Redix.PubSub.unsubscribe(conn, "#{Hermod.Settings.prefix}:#{channel}", self())
  end

  # Websocket client helper
  def add_pid_to_channel(pid, channel, %{ conn: conn, channels: channels } = state) do
    if Map.has_key?(channels, channel) == false do
      redis_subscribe(conn, channel)
    end

    channelPids = Map.get(channels, channel, MapSet.new)
    if MapSet.member?(channelPids, pid) do
      { :ok, state }
    else
      Logger.debug "subscribing process to #{channel}"
      Hermod.StatsHandler.increment_channel_clients(channel)

      channels = Map.put(channels, channel, MapSet.put(channelPids, pid))

      { :ok, %{state | channels: channels} }
    end
  end

  def delete_pid_from_channel(pid, channel, %{ conn: conn, channels: channels } = state) do
    channelPids = Map.get(channels, channel, MapSet.new)
    channelPids = MapSet.delete(channelPids, pid)
    channels = if(MapSet.size(channelPids) > 0, do: Map.put(channels, channel, channelPids), else: Map.delete(channels, channel))

    empty_channel = MapSet.size(Map.get(channels, channel, MapSet.new)) == 0

    Logger.debug "unsubscribing process to #{channel}"

    if empty_channel do
      redis_unsubscribe(conn, channel)
      Hermod.StatsHandler.delete_channel(channel)
      Logger.debug "Channel #{channel} empty, deleting"
    else
      Hermod.StatsHandler.decrement_channel_clients(channel)
    end

    { :ok, %{state | channels: channels} }
  end

  def cleanup_pid(pid, %{ conn: conn, channels: channels } = state) do
    # Loop over each channel and remove the pid
    channels = Enum.reduce(Map.keys(channels), channels, fn channel, map ->
      channelState = Map.get(map, channel)

      if (MapSet.member?(channelState, pid) == false) do
        map
      else
        Hermod.StatsHandler.decrement_channel_clients(channel)

        channelState = MapSet.delete(channelState, pid)

        if MapSet.size(channelState) == 0 do
          redis_unsubscribe(conn, channel)
          Hermod.StatsHandler.delete_channel(channel)
          Logger.debug "Channel #{channel} empty, deleting"
        end

        if(MapSet.size(channelState) > 0,
          do: Map.put(map, channel, channelState),
          else: Map.delete(map, channel)
        )
      end
    end)

    { :ok, %{ state | channels: channels } }
  end
end
