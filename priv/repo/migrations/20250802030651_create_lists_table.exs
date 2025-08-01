defmodule Javi.Repo.Migrations.CreateListsTable do
  use Ecto.Migration

  def change do
    create table(:lists) do
      add :name, :string, null: false
      add :description, :text
      add :is_public, :boolean, default: false
      # custom, favorites, watching, etc.
      add :list_type, :string, default: "custom"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:lists, [:user_id])
    create index(:lists, [:list_type])
    create index(:lists, [:is_public])
  end
end
