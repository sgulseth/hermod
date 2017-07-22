defmodule Hermod.WebsocketHandler do
  @behaviour :cowboy_websocket

  alias Hermod.RedisHandler

  @timeout 60000

  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  ## Callbacks

  def websocket_init(_type, req, _opts) do
    {:ok, req, %{}, @timeout}
  end

  def websocket_handle({:text, "ping"}, req, state) do
    {:reply, {:text, "pong"}, req, state}
  end

  def websocket_handle({:text, "subscribe:" <> topic}, req, state) do
    RedisHandler.subscribe(topic)

    {:ok, req, state}
  end
  def websocket_handle({:text, "unsubscribe:" <> topic}, req, state) do
    RedisHandler.unsubscribe(topic)

    {:ok, req, state}
  end
  def websocket_handle({:text, _}, req, state) do
    {:reply, {:text, "unknown_command"}, req, state}
  end

  def websocket_info(message, req, state) do
    {:reply, {:text, message}, req, state}
  end

  def terminate(_reason, req, state) do
    RedisHandler.cleanup()
    {:ok, req, state}
  end

end

