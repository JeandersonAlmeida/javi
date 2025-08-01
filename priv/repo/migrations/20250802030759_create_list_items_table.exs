defmodule Javi.Repo.Migrations.CreateListItemsTable do
  use Ecto.Migration

  def change do
    create table(:list_items) do
      add :list_id, references(:lists, on_delete: :delete_all), null: false
      add :title_id, references(:titles, on_delete: :delete_all), null: false
      add :position, :integer, default: 0
      add :notes, :text
      add :added_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:list_items, [:list_id])
    create index(:list_items, [:title_id])
    create index(:list_items, [:list_id, :position])

    create unique_index(:list_items, [:list_id, :title_id],
             name: :list_items_list_title_unique_index
           )
  end
end
