defmodule JaviWeb.WellKnownController do
  use JaviWeb, :controller

  # Responds to Chrome DevTools well-known file requests with an empty JSON object
  def chrome_devtools(conn, _params) do
    json(conn, %{})
  end
end
