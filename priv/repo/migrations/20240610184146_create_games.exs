defmodule LivePoker.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :quantity_stories, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
