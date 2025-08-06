defmodule JaviWeb.PWAControllerTest do
  use JaviWeb.ConnCase

  test "GET /manifest.json returns manifest file", %{conn: conn} do
    conn = get(conn, ~p"/manifest.json")
    assert response(conn, 200)
    content_type = conn.resp_headers |> Enum.find(fn {k, _} -> k == "content-type" end) |> elem(1)
    assert String.starts_with?(content_type, "application/json")
  end

  test "GET /sw.js returns service worker file", %{conn: conn} do
    conn = get(conn, ~p"/sw.js")
    assert response(conn, 200)
    content_type = conn.resp_headers |> Enum.find(fn {k, _} -> k == "content-type" end) |> elem(1)
    assert String.starts_with?(content_type, "application/javascript")
  end

  test "GET /pwa.js returns PWA script file", %{conn: conn} do
    conn = get(conn, ~p"/pwa.js")
    assert response(conn, 200)
    content_type = conn.resp_headers |> Enum.find(fn {k, _} -> k == "content-type" end) |> elem(1)
    assert String.starts_with?(content_type, "application/javascript")
  end
end
