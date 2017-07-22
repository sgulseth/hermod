defmodule Hermod.Http.DefaultHandler do
  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
    req = :cowboy_req.reply(200,
      %{
        "content-type" => "text/html"
      }, build_body(request), request)

    {:ok, req, state}
  end


  def terminate(_reason, _request, _state) do
    :ok
  end

  def build_body(_request) do
    """
    <html>
    <head>
      <title>Hermod</title>
    </head>
    <body>
      <div id='main'>
        <h1>Hermod</h1>
        <p> Redis PubSub router for websockets <h1>
      </div>
    </body>
    </html>
"""
  end

end
