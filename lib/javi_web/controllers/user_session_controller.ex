defmodule JaviWeb.UserSessionController do
  use JaviWeb, :controller

  alias Javi.Accounts
  alias JaviWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/configuracoes")
    |> create(params, "Conta criada com sucesso!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/configuracoes")
    |> create(params, "Senha atualizada com sucesso!")
  end

  def create(conn, params) do
    create(conn, params, "Bem-vindo de volta!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # Para evitar enumeração de usuários, não informe se o email está registrado.
      conn
      |> put_flash(:error, "Email ou senha inválidos")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/entrar")
    end
  end

  def logout(conn, _params) do
    conn
    |> put_flash(:info, "Logout realizado com sucesso.")
    |> UserAuth.log_out_user()
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logout realizado com sucesso.")
    |> UserAuth.log_out_user()
  end
end
