defmodule LivePoker.Repo.Migrations.CreateStories do
  use Ecto.Migration

  def change do
    create table(:stories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sequence_number, :integer
      add :name, :string
      add :description, :text
      add :final_estimate, :integer
      add :finished, :boolean, default: false, null: false
      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:stories, [:game_id])
  end
end
