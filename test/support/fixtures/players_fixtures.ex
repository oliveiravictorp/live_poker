defmodule LivePoker.PlayersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LivePoker.Players` context.
  """

  @doc """
  Generate a player.
  """
  def player_fixture(attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> Enum.into(%{
        moderator: true,
        spectator: true
      })
      |> LivePoker.Players.create_player()

    player
  end
end
