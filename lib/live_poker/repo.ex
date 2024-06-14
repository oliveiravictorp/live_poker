defmodule LivePoker.Repo do
  use Ecto.Repo,
    otp_app: :live_poker,
    adapter: Ecto.Adapters.Postgres
end
