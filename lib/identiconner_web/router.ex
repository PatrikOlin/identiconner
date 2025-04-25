defmodule IdenticonnerWeb.Router do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
    plug IdenticonnerWeb.Plugs.RateLimit, limit: 10, scale_ms: 60_000
  end

  scope "/api" do
    pipe_through :api

    get "/identicon/:text", IdenticonnerWeb.IdenticonController, :show

  end
end
