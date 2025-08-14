defmodule Javi.Repo.Migrations.CreateFriendRequests do
  use Ecto.Migration

  def change do
    create table(:friend_requests) do
      add :sender_id, references(:users, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create index(:friend_requests, [:sender_id])
    create index(:friend_requests, [:recipient_id])

    create unique_index(:friend_requests, [:sender_id, :recipient_id],
             name: :unique_friend_request_pair
           )

    create constraint(:friend_requests, :friend_requests_no_self,
             check: "sender_id <> recipient_id"
           )
  end
end
