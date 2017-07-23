defmodule Hermod.WebsocketHandler do
  @behaviour :cowboy_websocket
  require Logger
  alias Hermod.RedisHandler

  @timeout 60000

  def init(req, state) do
    {:cowboy_websocket, req, state, %{
        "idle_timeout": @timeout
      }
    }
  end

  ## Callbacks

  def websocket_init(state) do
    Hermod.StatsHandler.client_connect()
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

  def terminate(reason, _, state) do
    RedisHandler.cleanup()
    Hermod.StatsHandler.client_disconnect(reason)

    case reason do
      { :error, :closed } -> Logger.warn "Client brutally disconnected"
      { :error, :badencoding } -> Logger.warn "Client disconnected, bad encoding"
      { :error, :badframe } -> Logger.warn "Client disconnected, bad frame"
      { :error, :Reason } -> Logger.warn "Client disconnected, socket error"
      :timeout -> Logger.warn "Client disconnected, timeout"
    end

    {:ok, state}
  end

end

