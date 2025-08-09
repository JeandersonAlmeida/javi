defmodule Javi.Repo.Migrations.CreateStaffAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:staff_users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false

      add :name, :string, null: false
      # e.g. "superuser", "staff", "analyst"
      add :role, :string, null: false, default: "staff"
      # e.g. "active", "disabled"
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:staff_users, [:email])

    create table(:staff_users_tokens) do
      add :staff_user_id, references(:staff_users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:staff_users_tokens, [:staff_user_id])
    create unique_index(:staff_users_tokens, [:context, :token])
  end
end
