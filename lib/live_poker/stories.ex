defmodule LivePoker.Stories do
  @moduledoc """
  The Stories context.
  """

  import Ecto.Query, warn: false
  alias LivePoker.Repo

  alias LivePoker.Stories.Story

  @doc """
  Returns the list of stories.

  ## Examples

      iex> list_stories()
      [%Story{}, ...]

  """
  def list_stories(game_id) do
    Repo.all(
      from s in Story,
        where: s.game_id == ^game_id,
        order_by: [desc: s.sequence_number]
    )
  end

  def list_finished_stories(game_id) do
    Repo.all(
      from s in Story,
        where:
          s.game_id == ^game_id and
            s.finished == true
    )
  end

  def get_current_story(game_id) do
    Repo.one(
      from s in Story,
        where:
          s.game_id == ^game_id and
            s.finished == false
    )
  end

  @doc """
  Gets a single story.

  Raises `Ecto.NoResultsError` if the Story does not exist.

  ## Examples

      iex> get_story!(123)
      %Story{}

      iex> get_story!(456)
      ** (Ecto.NoResultsError)

  """
  def get_story!(id), do: Repo.get!(Story, id)

  @doc """
  Creates a story.

  ## Examples

      iex> create_story(%{field: value})
      {:ok, %Story{}}

      iex> create_story(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_story(attrs \\ %{}) do
    %Story{}
    |> Story.changeset(attrs)
    |> Repo.insert()
    |> broadcast_stories(:story_changed)
  end

  @doc """
  Updates a story.

  ## Examples

      iex> update_story(story, %{field: new_value})
      {:ok, %Story{}}

      iex> update_story(story, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_story(%Story{} = story, attrs) do
    story
    |> Story.changeset(attrs)
    |> Repo.update()
    |> broadcast_stories(:story_changed)
  end

  @doc """
  Deletes a story.

  ## Examples

      iex> delete_story(story)
      {:ok, %Story{}}

      iex> delete_story(story)
      {:error, %Ecto.Changeset{}}

  """
  def delete_story(%Story{} = story) do
    Repo.delete(story)
    |> broadcast_stories(:story_changed)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking story changes.

  ## Examples

      iex> change_story(story)
      %Ecto.Changeset{data: %Story{}}

  """
  def change_story(%Story{} = story, attrs \\ %{}) do
    Story.changeset(story, attrs)
  end

  alias LivePoker.Stories.Vote

  @doc """
  Returns the list of votes.

  ## Examples

      iex> list_votes()
      [%Vote{}, ...]

  """
  def list_votes(story_id) do
    Repo.all(
      from v in Vote,
        where: v.story_id == ^story_id
    )
    |> Repo.preload(player: :user)
  end

  @doc """
  Gets a single vote.

  Raises `Ecto.NoResultsError` if the Vote does not exist.

  ## Examples

      iex> get_vote!(123)
      %Vote{}

      iex> get_vote!(456)
      ** (Ecto.NoResultsError)

  """
  def get_vote!(id), do: Repo.get!(Vote, id)

  def get_vote_by_player(player_id, story_id) do
    Repo.one(
      from v in Vote,
        where:
          v.player_id == ^player_id and
            v.story_id == ^story_id
    )
  end

  @doc """
  Creates a vote.

  ## Examples

      iex> create_vote(%{field: value})
      {:ok, %Vote{}}

      iex> create_vote(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_vote(attrs \\ %{}) do
    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert()
    |> broadcast_votes(:vote_changed)
  end

  @doc """
  Updates a vote.

  ## Examples

      iex> update_vote(vote, %{field: new_value})
      {:ok, %Vote{}}

      iex> update_vote(vote, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_vote(%Vote{} = vote, attrs) do
    vote
    |> Vote.changeset(attrs)
    |> Repo.update()
    |> broadcast_votes(:vote_changed)
  end

  @doc """
  Deletes a vote.

  ## Examples

      iex> delete_vote(vote)
      {:ok, %Vote{}}

      iex> delete_vote(vote)
      {:error, %Ecto.Changeset{}}

  """
  def delete_vote(%Vote{} = vote) do
    Repo.delete(vote)
    |> broadcast_votes(:vote_changed)
  end

  def delete_all_votes(story_id) do
    query = from(v in Vote, where: v.story_id == ^story_id)

    Repo.delete_all(query)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vote changes.

  ## Examples

      iex> change_vote(vote)
      %Ecto.Changeset{data: %Vote{}}

  """
  def change_vote(%Vote{} = vote, attrs \\ %{}) do
    Vote.changeset(vote, attrs)
  end

  def subscribe_stories() do
    Phoenix.PubSub.subscribe(LivePoker.PubSub, "stories")
  end

  defp broadcast_stories({:error, _reason} = error, _event), do: error

  defp broadcast_stories({:ok, story}, event) do
    Phoenix.PubSub.broadcast(LivePoker.PubSub, "stories", {event, story})
    {:ok, story}
  end

  def subscribe_votes() do
    Phoenix.PubSub.subscribe(LivePoker.PubSub, "votes")
  end

  defp broadcast_votes({:error, _reason} = error, _event), do: error

  defp broadcast_votes({:ok, vote}, event) do
    Phoenix.PubSub.broadcast(LivePoker.PubSub, "votes", {event, vote})
    {:ok, vote}
  end
end
