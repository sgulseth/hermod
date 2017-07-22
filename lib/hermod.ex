defmodule Hermod do
  require Logger

  def start(_type, _args) do
    Logger.info "Starting Hermod ws<->pubsub on :#{Hermod.Settings.ws_port} with prefix #{Hermod.Settings.prefix}"
    { :ok, _ } = :cowboy.start_http(:http,
                                    100,
                                   [{:port, Hermod.Settings.ws_port}],
                                   [{ :env, [{:dispatch, dispatch()}]}]
                                   )
    Hermod.Supervisor.start_link

  end

  def dispatch do
    :cowboy_router.compile([
      { :_,
        [
          {"/", Hermod.WebsocketHandler, []},
          {:_, HttpHandler, []}
      ]}
    ])
  end
end
