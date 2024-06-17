defmodule LivePokerWeb.GameLive.Index do
  use LivePokerWeb, :live_view

  alias LivePoker.Games
  alias LivePoker.Games.Game

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    user_players =
      LivePoker.Players.list_players_by_user(user_id)

    games_list =
      for user_player <- user_players,
          do: Games.get_game!(user_player.game_id)

    {:ok,
     socket
     |> assign(user_id: user_id)
     |> stream(:games, games_list)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Game")
    |> assign(:game, Games.get_game!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create a new game")
    |> assign(:game, %Game{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Games")
    |> assign(:game, nil)
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
end
