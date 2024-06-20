defmodule LivePoker.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "games" do
    field :name, :string
    field :description, :string
    field :quantity_stories, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:name, :description, :quantity_stories])
    |> validate_required([:name, :quantity_stories])
  end
end
