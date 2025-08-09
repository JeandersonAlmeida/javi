defmodule Javi.Repo.Migrations.AddNicknameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :nickname, :citext
    end

    create unique_index(:users, [:nickname])
  end
end
