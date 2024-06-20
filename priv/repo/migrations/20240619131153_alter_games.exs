defmodule LivePoker.Repo.Migrations.AlterGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :quantity_stories, :integer
    end
  end
end
