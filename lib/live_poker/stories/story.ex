defmodule LivePoker.Stories.Story do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "stories" do
    field :name, :string
    field :finished, :boolean, default: false
    field :description, :string
    field :sequence_number, :integer
    field :final_estimate, :integer
    belongs_to :game_id, LivePoker.Games.Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(story, attrs) do
    story
    |> cast(attrs, [:sequence_number, :name, :description, :final_estimate, :finished])
    |> validate_required([:sequence_number, :name, :finished])
  end
end
