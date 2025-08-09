defmodule Javi.Repo.Migrations.BootstrapOpsSuperuser do
  use Ecto.Migration

  alias Javi.Repo

  def up do
    email = System.get_env("OPS_ADMIN_EMAIL") || "superadmin@javi.com"
    password = System.get_env("OPS_ADMIN_PASSWORD") || "superadmin123@javi.com"
    name = System.get_env("OPS_ADMIN_NAME") || "Superuser"

    # Ensure citext extension exists in case this migration runs standalone
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    existing =
      Ecto.Adapters.SQL.query!(Repo, "SELECT 1 FROM staff_users WHERE email = $1 LIMIT 1", [email])

    if existing.num_rows == 0 do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      hashed_password = Bcrypt.hash_pwd_salt(password)

      Ecto.Adapters.SQL.query!(
        Repo,
        """
        INSERT INTO staff_users (email, hashed_password, name, role, status, inserted_at, updated_at)
        VALUES ($1, $2, $3, 'superuser', 'active', $4, $4)
        """,
        [email, hashed_password, name, now]
      )
    end
  end

  def down do
    email = System.get_env("OPS_ADMIN_EMAIL") || "superadmin@javi.com"
    Ecto.Adapters.SQL.query!(Repo, "DELETE FROM staff_users WHERE email = $1", [email])
  end
end
