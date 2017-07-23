defmodule Hermod.Settings do
  import EnvHelper

  system_env(:ws_port, 8080, :string_to_integer)
  system_env(:prefix, "hermod")

  system_env(:redis_host, "localhost")
  system_env(:redis_port, 6379, :string_to_integer)
end
