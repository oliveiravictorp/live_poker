defmodule LivePoker.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias LivePoker.Repo
  alias LivePoker.Players.Player

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players()
      [%Player{}, ...]

  """
  def list_players_by_user(user_id) do
    Repo.all(
      from p in Player,
        where: p.user_id == ^user_id
    )
  end

  def list_players_by_game(game_id) do
    Repo.all(
      from p in Player,
        where:
          p.game_id == ^game_id and
            p.moderator == false
    )
    |> Repo.preload(:user)
  end

  def list_moderators_by_game(game_id) do
    Repo.all(
      from p in Player,
        where:
          p.game_id == ^game_id and
            p.moderator == true
    )
    |> Repo.preload(:user)
  end

  def get_player_by_game_and_user(game_id, user_id) do
    case Repo.one(
           from p in Player,
             where:
               p.game_id == ^game_id and
                 p.user_id == ^user_id
         ) do
      nil ->
        %{}
        |> Map.put("user_id", user_id)
        |> Map.put("game_id", game_id)
        |> create_player()

      %Player{} = player ->
        {:ok, player}
    end
  end

  @doc """
  Checks if a player is a moderator.

  ## Examples

      iex> is_moderator?(%Player{moderator: true})
      true

      iex> is_moderator?(%Player{moderator: false})
      false

  """
  def is_moderator?(%Player{moderator: moderator}), do: moderator

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_player!(id), do: Repo.get!(Player, id)

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(%{field: value})
      {:ok, %Player{}}

      iex> create_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
    |> broadcast_players(:player_changed)
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
    |> broadcast_players(:player_changed)
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(player)
      {:ok, %Player{}}

      iex> delete_player(player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Player{} = player) do
    Repo.delete(player)
    |> broadcast_players(:player_changed)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end

  def subscribe_players() do
    Phoenix.PubSub.subscribe(LivePoker.PubSub, "players")
  end

  defp broadcast_players({:error, _reason} = error, _event), do: error

  defp broadcast_players({:ok, player}, event) do
    Phoenix.PubSub.broadcast(LivePoker.PubSub, "players", {event, player})
    {:ok, player}
  end
end
