FROM bitwalker/alpine-elixir-phoenix

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY mix.exs .
COPY mix.lock .

ENV MIX_ENV=prod REPLACE_OS_VARS=true VM_HOST=127.0.0.1

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mix deps.get && mix deps.compile

COPY . .

RUN mix compile && mix release

CMD ["/usr/src/app/_build/prod/rel/Hermod/bin/Hermod", "foreground"]
