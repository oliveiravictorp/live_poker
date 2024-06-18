defmodule LivePoker.Stories.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    field :estimate, :integer
    belongs_to :player_id, LivePoker.Players.Player
    belongs_to :story_id, LivePoker.Stories.Story

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:estimate])
    |> validate_required([:estimate])
  end
end
