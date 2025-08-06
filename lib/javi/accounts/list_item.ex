defmodule Javi.Accounts.ListItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "list_items" do
    field :position, :integer, default: 0
    field :notes, :string
    field :rating, :integer
    field :added_at, :utc_datetime

    belongs_to :list, Javi.Accounts.List
    belongs_to :title, Javi.Media.Title

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(list_item, attrs) do
    list_item
    |> cast(attrs, [:position, :notes, :rating, :list_id, :title_id])
    |> validate_required([:list_id, :title_id])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_length(:notes, max: 1000)
    |> foreign_key_constraint(:list_id)
    |> foreign_key_constraint(:title_id)
    |> unique_constraint([:list_id, :title_id], name: :list_items_list_title_unique_index)
  end

  @doc """
  Creates a changeset for adding a title to a list.
  """
  def create_changeset(list_item, attrs) do
    list_item
    |> changeset(attrs)
    |> put_change(:added_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Creates a changeset for updating a list item.
  """
  def update_changeset(list_item, attrs) do
    list_item
    |> changeset(attrs)
  end
end
