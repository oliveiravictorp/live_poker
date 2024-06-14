defmodule LivePoker.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "players" do
    field :name, :string
    field :moderator, :boolean, default: false
    field :spectator, :boolean, default: false
    belongs_to :game, LivePoker.Games.Game
    belongs_to :user, LivePoker.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:name, :moderator, :spectator, :game_id, :user_id])
    |> validate_required([:name, :moderator, :spectator, :user_id])
  end
end
