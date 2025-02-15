defmodule LivePoker.Stories.Story do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "stories" do
    field :sequence_number, :integer
    field :name, :string
    field :description, :string
    field :final_estimate, :integer
    field :finished, :boolean, default: false
    belongs_to :game, LivePoker.Games.Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(story, attrs \\ %{}) do
    story
    |> cast(attrs, [:sequence_number, :name, :description, :final_estimate, :finished, :game_id])
    |> validate_required([:sequence_number, :name, :finished, :game_id])
  end
end
