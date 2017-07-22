defmodule Hermod do
  require Logger

  def start(_type, _args) do
    Logger.info "Starting Hermod ws<->pubsub on :#{Hermod.Settings.ws_port} with prefix #{Hermod.Settings.prefix}"
    { :ok, _ } = :cowboy.start_clear(:http,
                                   [{:port, Hermod.Settings.ws_port}],
                                   %{ env: %{ dispatch: dispatch() } }
                                   )
    Hermod.Supervisor.start_link

  end

  def dispatch do
    :cowboy_router.compile([
      { :_,
        [
          {"/", Hermod.WebsocketHandler, []},
          {"/stats", Hermod.Http.StatsHandler, []},
          {:_, Hermod.Http.DefaultHandler, []}
      ]}
    ])
  end
end
