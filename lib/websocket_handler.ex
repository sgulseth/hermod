defmodule Hermod.WebsocketHandler do
  @behaviour :cowboy_websocket

  alias Hermod.RedisHandler

  @timeout 60000

  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  ## Callbacks

  def websocket_init(state) do
    Hermod.StatsHandler.increment_clients()
    {:ok, state}
  end

  def websocket_handle({:text, "ping"}, state) do
    {:reply, {:text, "pong"}, state}
  end

  def websocket_handle({:text, "subscribe:" <> topic}, state) do
    RedisHandler.subscribe(topic)

    {:ok, state}
  end
  def websocket_handle({:text, "unsubscribe:" <> topic}, state) do
    RedisHandler.unsubscribe(topic)

    {:ok, state}
  end
  def websocket_handle({:text, _}, state) do
    {:reply, {:text, "unknown_command"}, state}
  end

  def websocket_info(message, state) do
    {:reply, {:text, message}, state}
  end

  def terminate(_reason, _, state) do
    RedisHandler.cleanup()
    Hermod.StatsHandler.decrement_clients()
    {:ok, state}
  end

end

