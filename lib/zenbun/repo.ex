defmodule Zenbun.Repo do
  use Ecto.Repo,
    otp_app: :zenbun,
    adapter: Ecto.Adapters.Postgres
end
