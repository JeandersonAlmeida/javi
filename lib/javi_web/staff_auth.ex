defmodule JaviWeb.StaffAuth do
  use JaviWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Javi.Accounts

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_javi_web_staff_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  # Session helpers

  def log_in_staff(conn, staff, params \\ %{}) do
    token = Accounts.generate_staff_user_session_token(staff)
    staff_return_to = get_session(conn, :staff_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: staff_return_to || signed_in_path(conn))
  end

  def log_out_staff(conn) do
    staff_token = get_session(conn, :staff_token)
    staff_token && Accounts.delete_staff_user_session_token(staff_token)

    if staff_live_socket_id = get_session(conn, :staff_live_socket_id) do
      JaviWeb.Endpoint.broadcast(staff_live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/ops/login")
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  # Fetch/assign current staff

  def fetch_current_staff(conn, _opts) do
    {staff_token, conn} = ensure_staff_token(conn)
    staff = staff_token && Accounts.get_staff_user_by_session_token(staff_token)
    assign(conn, :current_staff, staff)
  end

  defp ensure_staff_token(conn) do
    if token = get_session(conn, :staff_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:staff_token, token)
    |> put_session(:staff_live_socket_id, "staff_sessions:#{Base.url_encode64(token)}")
  end

  # Router plugs

  def redirect_if_staff_is_authenticated(conn, _opts) do
    if conn.assigns[:current_staff] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  def require_authenticated_staff(conn, _opts) do
    if conn.assigns[:current_staff] do
      conn
    else
      conn
      |> put_flash(:error, "Você deve fazer login como staff para acessar esta página.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/ops/login")
      |> halt()
    end
  end

  # LiveView on_mount helpers

  def on_mount(:mount_current_staff, _params, session, socket) do
    {:cont, mount_current_staff(socket, session)}
  end

  def on_mount(:ensure_staff_authenticated, _params, session, socket) do
    socket = mount_current_staff(socket, session)

    if socket.assigns.current_staff do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(
          :error,
          "Você deve fazer login como staff para acessar esta página."
        )
        |> Phoenix.LiveView.redirect(to: ~p"/ops/login")

      {:halt, socket}
    end
  end

  defp mount_current_staff(socket, session) do
    Phoenix.Component.assign_new(socket, :current_staff, fn ->
      if staff_token = session["staff_token"] do
        Accounts.get_staff_user_by_session_token(staff_token)
      end
    end)
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :staff_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/ops"
end
