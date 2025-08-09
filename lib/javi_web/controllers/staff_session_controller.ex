defmodule JaviWeb.StaffSessionController do
  use JaviWeb, :controller

  alias Javi.Accounts
  alias Javi.Accounts.StaffUser
  import JaviWeb.StaffAuth

  # The /ops/login page is handled by LiveView. This controller only handles POST/DELETE.

  def create(conn, params) do
    # Support either top-level params or namespaced ones (e.g., "staff[email]")
    email = params["email"] || get_in(params, ["staff", "email"]) || ""
    password = params["password"] || get_in(params, ["staff", "password"]) || ""

    case Accounts.get_staff_user_by_email_and_password(email, password) do
      %StaffUser{status: "active"} = staff ->
        log_in_staff(conn, staff, params)

      %StaffUser{status: status} when status != "active" ->
        conn
        |> put_flash(:error, "Sua conta de staff está #{status}.")
        |> redirect(to: ~p"/ops/login")

      _ ->
        conn
        |> put_flash(:error, "Credenciais inválidas.")
        |> redirect(to: ~p"/ops/login")
    end
  end

  def delete(conn, _params) do
    log_out_staff(conn)
  end
end
