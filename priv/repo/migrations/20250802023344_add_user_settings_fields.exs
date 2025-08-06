defmodule Javi.Repo.Migrations.AddUserSettingsFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Photo field
      add :photo_url, :string

      # Privacy settings
      add :public_profile, :boolean, default: true
      add :show_activity, :boolean, default: true
      add :allow_messages, :boolean, default: true

      # Social settings
      add :follower_notifications, :boolean, default: true
      add :share_lists, :boolean, default: true
      add :social_recommendations, :boolean, default: true
    end
  end
end
