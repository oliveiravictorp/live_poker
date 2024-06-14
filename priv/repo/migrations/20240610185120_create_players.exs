defmodule LivePoker.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :moderator, :boolean, default: false, null: false
      add :spectator, :boolean, default: false, null: false
      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:players, [:game_id, :user_id])
  end
end
