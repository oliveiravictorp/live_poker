defmodule LivePokerWeb.GameLive.Index do
  use LivePokerWeb, :live_view

  alias LivePoker.Games
  alias LivePoker.Games.Game
  alias LivePoker.Players

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    user_players =
      Players.list_players_by_user(user_id)

    games_list =
      for user_player <- user_players do
        Games.get_game!(user_player.game_id)
      end

    {:ok,
     socket
     |> assign(user_id: user_id)
     |> stream(:games, games_list)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"game_id" => game_id}) do
    socket
    |> assign(
      page_title: "Edit game",
      game: Games.get_game!(game_id)
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: "Create a new game",
      game: %Game{}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: "Listing games",
      game: nil
    )
  end

  @impl true
  def handle_info({LivePokerWeb.GameLive.FormComponent, {:saved, game}}, socket) do
    {:noreply, stream_insert(socket, :games, game)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    game = Games.get_game!(id)
    {:ok, _} = Games.delete_game(game)

    {:noreply, stream_delete(socket, :games, game)}
  end

  defp check_moderator(game_id, user_id) do
    {:ok, player} = Players.get_player_by_game_and_user(game_id, user_id)

    if player.moderator do
      true
    else
      false
    end
  end
end
