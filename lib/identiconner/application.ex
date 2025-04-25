defmodule Identiconner.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      #IdenticonnerWeb.Telemetry,
      {Phoenix.PubSub, name: Identiconner.PubSub},
      #IdenticonnerWeb.Endpoint,
      {Plug.Cowboy, scheme: :http, plug: IdenticonnerWeb.Router, options: [port: 4000]},
      {IdenticonnerWeb.RateLimit.Application, [scale_ms: 60_000]}
    ]

    opts = [strategy: :one_for_one, name: Identiconner.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
