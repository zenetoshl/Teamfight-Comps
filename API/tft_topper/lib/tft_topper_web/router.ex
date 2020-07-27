defmodule TftTopperWeb.Router do
  use TftTopperWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TftTopperWeb do
    pipe_through :api
    get "/init", DataController, :init
    get "/reset", DataController, :reset
    get "/comps", DataController, :get_comps
    get "/items", DataController, :get_items
  end

  # Other scopes may use custom stacks.
  # scope "/api", TftTopperWeb do
  #   pipe_through :api
  # end
end
