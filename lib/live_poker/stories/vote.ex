defmodule LivePoker.Stories.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    field :estimate, :integer
    belongs_to :player, LivePoker.Players.Player
    belongs_to :story, LivePoker.Stories.Story

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs \\ %{}) do
    vote
    |> cast(attrs, [:estimate, :player_id, :story_id])
    |> validate_required([:estimate, :player_id, :story_id])
  end
end
