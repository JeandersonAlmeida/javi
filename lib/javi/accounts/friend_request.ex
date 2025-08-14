defmodule Javi.Accounts.FriendRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending)a

  schema "friend_requests" do
    belongs_to :sender, Javi.Accounts.User
    belongs_to :recipient, Javi.Accounts.User
    field :status, Ecto.Enum, values: @statuses, default: :pending

    timestamps()
  end

  def create_changeset(request, attrs) do
    request
    |> cast(attrs, [:sender_id, :recipient_id, :status])
    |> validate_required([:sender_id, :recipient_id])
    |> validate_number(:sender_id, greater_than: 0)
    |> validate_number(:recipient_id, greater_than: 0)
    |> then(fn cs ->
      validate_change(cs, :recipient_id, fn :recipient_id, recipient_id ->
        sender_id = get_field(cs, :sender_id)

        if recipient_id == sender_id do
          [recipient_id: "não pode enviar solicitação a si mesmo"]
        else
          []
        end
      end)
    end)
    |> put_change(:status, :pending)
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:recipient_id)
    |> unique_constraint([:sender_id, :recipient_id],
      name: :unique_friend_request_pair,
      message: "solicitação já enviada"
    )
    |> check_constraint(:sender_id, name: :friend_requests_no_self)
  end
end
