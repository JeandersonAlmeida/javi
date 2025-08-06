defmodule JaviWeb.PWAController do
  use JaviWeb, :controller

  def manifest(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_file(200, "priv/static/manifest.json")
  end

  def service_worker(conn, _params) do
    conn
    |> put_resp_content_type("application/javascript")
    |> send_file(200, "priv/static/sw.js")
  end

  def pwa_script(conn, _params) do
    conn
    |> put_resp_content_type("application/javascript")
    |> send_file(200, "priv/static/pwa.js")
  end
end
