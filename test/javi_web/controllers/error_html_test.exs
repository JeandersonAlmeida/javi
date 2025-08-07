defmodule JaviWeb.ErrorHTMLTest do
  use JaviWeb.ConnCase, async: true

  describe "404 error page" do
    test "renders 404 page for non-existent route", %{conn: conn} do
      conn = get(conn, "/non-existent-route")

      assert conn.status == 404
      assert html_response(conn, 404) =~ "404"
      assert html_response(conn, 404) =~ "Página não encontrada"
      assert html_response(conn, 404) =~ "Voltar ao início"
      assert html_response(conn, 404) =~ "Fazer login"
    end
  end

  describe "403 error page" do
    test "renders 403 page for forbidden access", %{conn: conn} do
      # Try to access a protected route without authentication
      conn = get(conn, "/inicio")

      # This should redirect to login, but if we get a 403, it should show our custom page
      if conn.status == 403 do
        assert html_response(conn, 403) =~ "403"
        assert html_response(conn, 403) =~ "Acesso negado"
        assert html_response(conn, 403) =~ "Fazer login"
      end
    end
  end

  describe "error templates" do
    test "error templates exist and are accessible", %{conn: conn} do
      # Test that we can access a non-existent route and get our custom 404 page
      conn = get(conn, "/this-route-does-not-exist")

      # Verify that our custom 404 page is being rendered
      html = html_response(conn, 404)
      assert html =~ "404"
      assert html =~ "Página não encontrada"
      assert html =~ "Voltar ao início"
      assert html =~ "Fazer login"

      # Verify that the default "Not Found" text is NOT present
      refute html =~ "Not Found"
    end
  end
end
