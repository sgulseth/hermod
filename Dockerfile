FROM elixir:1.4

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY mix.exs .
COPY mix.lock .

ENV MIX_ENV=prod

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mix deps.get && mix deps.compile

COPY . .

RUN mix compile && mix release

CMD ["/usr/src/app/_build/prod/rel/Hermod/bin/Hermod", "foreground"]
