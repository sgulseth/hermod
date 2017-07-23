# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  backends: [:console], # default, support for additional log sinks
  compile_time_purge_level: :info # purges logs with lower level than this

import_config "#{Mix.env}.exs"
