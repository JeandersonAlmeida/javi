defmodule Javi.Accounts.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :name, :string
    field :description, :string
    field :is_public, :boolean, default: false
    field :list_type, :string, default: "custom"

    belongs_to :user, Javi.Accounts.User
    has_many :list_items, Javi.Accounts.ListItem
    has_many :titles, through: [:list_items, :title]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:name, :description, :is_public, :list_type, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_inclusion(:list_type, [
      "custom",
      "favorites",
      "watching",
      "watched",
      "want_to_watch"
    ])
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Creates a changeset for creating a new list.
  """
  def create_changeset(list, attrs) do
    list
    |> changeset(attrs)
  end

  @doc """
  Creates a changeset for updating a list.
  """
  def update_changeset(list, attrs) do
    list
    |> changeset(attrs)
  end
end
