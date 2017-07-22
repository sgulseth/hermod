defmodule Hermod.Http.StatsHandler do
  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
    Hermod.StatsHandler.get_stats()

    stats  = receive do
      stats -> stats
    end

    req = :cowboy_req.reply(200,
    %{
      "content-type" => "text/html",
      "cache-control" => "no-cache"
    }, stats, request)

    { :ok, req, state }
  end


  def terminate(_reason, _request, _state) do
    :ok
  end
end
