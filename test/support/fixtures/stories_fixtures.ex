defmodule LivePoker.StoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LivePoker.Stories` context.
  """

  @doc """
  Generate a story.
  """
  def story_fixture(attrs \\ %{}) do
    {:ok, story} =
      attrs
      |> Enum.into(%{
        description: "some description",
        final_estimate: 42,
        finished: true,
        name: "some name",
        sequence_number: 42
      })
      |> LivePoker.Stories.create_story()

    story
  end

  @doc """
  Generate a vote.
  """
  def vote_fixture(attrs \\ %{}) do
    {:ok, vote} =
      attrs
      |> Enum.into(%{
        estimate: 42
      })
      |> LivePoker.Stories.create_vote()

    vote
  end
end
