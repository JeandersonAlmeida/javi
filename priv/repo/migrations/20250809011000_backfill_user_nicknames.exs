defmodule Javi.Repo.Migrations.BackfillUserNicknames do
  use Ecto.Migration
  import Ecto.Query

  def up do
    repo = repo()

    users =
      repo.all(
        from(u in "users",
          where: is_nil(u.nickname) or u.nickname == "",
          select: %{id: u.id, display_name: u.display_name, email: u.email}
        )
      )

    Enum.each(users, fn user ->
      base =
        cond do
          is_binary(user.display_name) and String.trim(user.display_name) != "" ->
            user.display_name

          is_binary(user.email) and String.trim(user.email) != "" ->
            user.email |> String.split("@") |> List.first()

          true ->
            "user"
        end

      normalized = normalize_nickname(base)
      nickname = generate_unique_nickname(repo, normalized, user.id)

      repo.update_all(from(u in "users", where: u.id == ^user.id), set: [nickname: nickname])
    end)
  end

  # We do not attempt to revert the backfilled values automatically as users may have
  # already edited their nicknames after this migration. No-op.
  def down, do: :ok

  # --- local helpers (kept inside migration to avoid coupling to app modules) ---

  defp normalize_nickname(nil), do: "user"

  defp normalize_nickname(nickname) when is_binary(nickname) do
    nickname
    |> String.downcase()
    |> String.trim()
    # keep a-z, 0-9, dot, underscore, hyphen; replace others with hyphen
    |> String.replace(~r/[^a-z0-9._-]+/u, "-")
    # collapse repeated separators
    |> String.replace(~r/[-_.]{2,}/, "-")
    # trim separators from both ends
    |> String.trim("-._")
    |> case do
      "" -> "user"
      s -> s
    end
  end

  defp generate_unique_nickname(repo, base, current_id) do
    base = normalize_nickname(base)

    if unique?(repo, base, current_id) do
      base
    else
      Stream.iterate(2, &(&1 + 1))
      |> Enum.find_value(fn n ->
        candidate = "#{base}-#{n}"
        if unique?(repo, candidate, current_id), do: candidate, else: nil
      end) || "#{base}-#{System.unique_integer([:positive])}"
    end
  end

  defp unique?(repo, nickname, current_id) do
    count =
      repo.one(
        from(u in "users",
          where: u.nickname == ^nickname and u.id != ^current_id,
          select: count(u.id)
        )
      )

    count == 0
  end
end
