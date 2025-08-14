defmodule Javi.Repo.Migrations.CreateFriendships do
  use Ecto.Migration

  def change do
    create table(:friendships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :friend_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:friendships, [:user_id])
    create index(:friendships, [:friend_id])
    create unique_index(:friendships, [:user_id, :friend_id], name: :unique_friend_pair)

    # Enforce canonical ordering user_id < friend_id to avoid duplicates
    create constraint(:friendships, :friendships_canonical_order, check: "user_id < friend_id")

    # Prevent self-friendship at DB level too (redundant if canonical order holds but explicit)
    create constraint(:friendships, :friendships_no_self, check: "user_id <> friend_id")
  end
end
