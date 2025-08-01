defmodule JaviWeb.LandingController do
  use JaviWeb, :controller

  def index(conn, _params) do
    # Show landing page to everyone (authenticated and unauthenticated)
    render(conn, :index)
  end
end
