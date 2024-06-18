defmodule LivePoker.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :estimate, :integer
      add :player_id, references(:players, on_delete: :delete_all, type: :binary_id)
      add :story_id, references(:stories, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:votes, [:player_id])
    create index(:votes, [:story_id])
  end
end
