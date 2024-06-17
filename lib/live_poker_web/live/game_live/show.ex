defmodule LivePokerWeb.GameLive.Show do
  use LivePokerWeb, :live_view

  alias LivePoker.Games
  alias LivePoker.Players

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:game, Games.get_game!(id))
     |> stream(:players, Players.list_players_by_game(id))
     |> assign(
       :user_player,
       Players.get_player_by_game_and_user(
         id,
         socket.assigns.current_user.id
       )
     )}
  end

  defp page_title(:show), do: "Show game"
  defp page_title(:edit), do: "Edit game"
end
