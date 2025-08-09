defmodule Javi.Accounts.StaffUserToken do
  use Ecto.Schema
  import Ecto.Query
  alias __MODULE__

  @rand_size 32

  @session_validity_in_days 60

  schema "staff_users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :staff_user, Javi.Accounts.StaffUser

    timestamps(type: :utc_datetime, updated_at: false)
  end

  # Session token (binary, not hashed)
  def build_session_token(staff) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %StaffUserToken{token: token, context: "session", staff_user_id: staff.id}}
  end

  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: staff in assoc(token, :staff_user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: staff

    {:ok, query}
  end

  # Generic helpers
  def by_token_and_context_query(token, context) do
    from StaffUserToken, where: [token: ^token, context: ^context]
  end

  def by_staff_and_contexts_query(staff, :all) do
    from t in StaffUserToken, where: t.staff_user_id == ^staff.id
  end

  def by_staff_and_contexts_query(staff, [_ | _] = contexts) do
    from t in StaffUserToken, where: t.staff_user_id == ^staff.id and t.context in ^contexts
  end
end
