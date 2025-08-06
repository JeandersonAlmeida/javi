defmodule Javi.Repo.Migrations.AddRatingToListItems do
  use Ecto.Migration

  def change do
    alter table(:list_items) do
      add :rating, :integer
    end
  end
end
