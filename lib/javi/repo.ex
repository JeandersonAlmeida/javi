defmodule Javi.Repo do
  use Ecto.Repo,
    otp_app: :javi,
    adapter: Ecto.Adapters.Postgres
end
