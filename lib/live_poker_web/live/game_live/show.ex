defmodule LivePokerWeb.GameLive.Show do
  use LivePokerWeb, :live_view

  alias LivePoker.Games
  alias LivePoker.Players
  alias LivePoker.Stories
  alias LivePoker.Stories.Story

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => game_id}, _, socket) do
    game = Games.get_game!(game_id)

    new_story = %Story{}

    change_story = Stories.change_story(new_story)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:game, game)
     |> stream(:players, Players.list_players_by_game(game_id))
     |> assign(
       :user_player,
       Players.get_player_by_game_and_user(
         game_id,
         socket.assigns.current_user.id
       )
     )
     |> assign(:story_form, to_form(change_story))
     |> assign(:story, new_story)
     |> assign(:stories, Stories.list_stories(game_id))}
  end

  @impl true
  def handle_event("validate_story", %{"story" => story_params}, socket) do
    change_story =
      socket.assigns.story
      |> Stories.change_story(story_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:story_form, to_form(change_story))}
  end

  @impl true
  def handle_event("save_story", %{"story" => story_params}, socket) do
    save_story(socket, story_params)
  end

  defp save_story(socket, story_params) do
    game = socket.assigns.game

    story_params =
      story_params
      |> Map.put("sequence_number", game.quantity_stories + 1)
      |> Map.put("final_estimate", 0)
      |> Map.put("game_id", game.id)

    case Stories.create_story(story_params) do
      {:ok, story} ->
        game_params =
          %{}
          |> Map.put("quantity_stories", story.sequence_number)

        Games.update_game(game, game_params)
        notify_parent({:saved, story})

        {:noreply,
         socket
         |> put_flash(:info, "Story created successfully")
         |> push_patch(to: ~p"/games/#{game.id}")}

      {:error, %Ecto.Changeset{} = change_story} ->
        {:noreply,
         socket
         |> assign(:story_form, to_form(change_story))}
    end
  end

  defp page_title(:show), do: "Play game"
  defp page_title(:edit), do: "Edit game"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
