defmodule Javi.Accounts.StaffUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "staff_users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true

    field :name, :string
    # "superuser" | "staff" | "analyst" ...
    field :role, :string, default: "staff"
    # "active" | "disabled"
    field :status, :string, default: "active"

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(staff, attrs, opts \\ []) do
    staff
    |> cast(attrs, [:email, :password, :name, :role, :status])
    |> validate_required([:email, :password, :name])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Javi.Repo)
    |> unique_constraint(:email)
    |> validate_length(:password, min: 6, max: 72)
    |> maybe_hash_password(opts)
    |> validate_inclusion(:role, ["superuser", "staff", "analyst"])
    |> validate_inclusion(:status, ["active", "disabled"])
  end

  def password_changeset(staff, attrs, opts \\ []) do
    staff
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    |> maybe_hash_password(opts)
  end

  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    # Use && to allow truthy checks; "and" requires strict booleans and will crash with strings.
    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
