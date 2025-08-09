# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Javi.Repo.insert!(%Javi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Superuser bootstrap moved to migration:
# priv/repo/migrations/20250809000100_bootstrap_ops_superuser.exs
