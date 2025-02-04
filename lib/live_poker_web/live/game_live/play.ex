defmodule LivePokerWeb.GameLive.Play do
  use LivePokerWeb, :live_view

  alias LivePoker.Games
  alias LivePoker.Players
  alias LivePoker.Stories
  alias LivePoker.Stories.Story
  alias LivePoker.Presence

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:stories, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :play, %{"game_id" => game_id}) do
    if connected?(socket), do: Stories.subscribe()

    new_story = %Story{}
    change_story = Stories.change_story(new_story)

    stories = Stories.list_stories(game_id)
    finished_stories = Stories.list_finished_stories(game_id)
    new_story_available = length(stories) - length(finished_stories)

    estimates = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, "?"]

    current_story = Stories.get_current_story(game_id)

    votes =
      case current_story do
        nil ->
          nil

        %Story{} = current_story ->
          Stories.list_votes(current_story.id)
      end

    topic = "game:#{game_id}"
    user = socket.assigns.current_user

    LivePokerWeb.Endpoint.subscribe(topic)
    Presence.track(self(), topic, user.id, user)
    presences = Presence.list(topic)

    socket
    |> assign(:page_title, "Play game")
    |> assign(:game, Games.get_game!(game_id))
    |> stream(:players, Players.list_players_by_game(game_id))
    |> assign(
      :user_player,
      Players.get_player_by_game_and_user(
        game_id,
        socket.assigns.current_user.id
      )
    )
    |> assign(:presences, presences)
    |> assign(:topic, topic)
    |> assign(:story, new_story)
    |> assign(:story_form, to_form(change_story))
    |> assign(:stories, stories)
    |> assign(:current_story, current_story)
    |> assign(:votes, votes)
    |> assign(:estimates, estimates)
    |> assign(:new_story_available, new_story_available)
  end

  defp apply_action(socket, :edit_game, %{"game_id" => game_id}) do
    socket
    |> assign(:page_title, "Edit game")
    |> assign(:game, Games.get_game!(game_id))
  end

  defp apply_action(socket, :edit_player, %{"player_id" => player_id}) do
    socket
    |> assign(:page_title, "Edit player")
    |> assign(:player, Players.get_player!(player_id))
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    presences = Presence.list(socket.assigns.topic)
    {:noreply, assign(socket, presences: presences)}
  end

  @impl true
  def handle_info({:story_created, story}, socket) do
    {:noreply, stream_insert(socket, :stories, story)}
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
         |> push_patch(to: ~p"/game/#{game.id}")}

      {:error, %Ecto.Changeset{} = change_story} ->
        {:noreply,
         socket
         |> assign(:story_form, to_form(change_story))}
    end
  end

  @impl true
  def handle_event("accept_story", %{"id" => id, "game_id" => game_id}, socket) do
    attrs =
      %{}
      |> Map.put("finished", true)

    Stories.get_story!(id)
    |> Stories.update_story(attrs)

    {:noreply, socket |> push_patch(to: ~p"/game/#{game_id}")}
  end

  @impl true
  def handle_event("restart_story", %{"id" => id, "game_id" => game_id}, socket) do
    Stories.delete_all_votes(id)

    attrs =
      %{}
      |> Map.put("final_estimate", 0)

    Stories.get_story!(id)
    |> Stories.update_story(attrs)

    {:noreply, socket |> push_patch(to: ~p"/game/#{game_id}")}
  end

  @impl true
  def handle_event("reveal_cards", %{"id" => id, "game_id" => game_id}, socket) do
    calc_final_estimate(id)

    {:noreply, socket |> push_patch(to: ~p"/game/#{game_id}")}
  end

  @impl true
  def handle_event(
        "estimate_vote",
        %{
          "estimate" => estimate,
          "player_id" => player_id,
          "story_id" => story_id,
          "game_id" => game_id,
          "topic" => topic
        },
        socket
      ) do
    attrs =
      %{}
      |> Map.put(
        "estimate",
        if estimate == "?" do
          0
        else
          estimate
        end
      )

    case Stories.get_vote_by_player(player_id, story_id) do
      nil ->
        Stories.create_vote(
          attrs
          |> Map.put("player_id", player_id)
          |> Map.put("story_id", story_id)
        )

      %Stories.Vote{} = vote ->
        Stories.update_vote(vote, attrs)
    end

    votes_qtt = Stories.list_votes(story_id) |> length()
    players_qtt = Presence.list(topic) |> map_size()
    # IO.puts("Votos: #{votes_qtt}, Jogadores Online: #{players_qtt}")

    if votes_qtt == players_qtt do
      # IO.puts("Todos votaram! Calculando estimativa final...")
      calc_final_estimate(story_id)
    end

    {:noreply, socket |> push_patch(to: ~p"/game/#{game_id}")}
  end

  @impl true
  def handle_event("delete_story", %{"id" => id}, socket) do
    story = Stories.get_story!(id)
    {:ok, _} = Stories.delete_story(story)

    {:noreply, stream_delete(socket, :stories, story)}
  end

  @impl true
  def handle_event("delete_player", %{"id" => id}, socket) do
    player = Players.get_player!(id)
    {:ok, _} = Players.delete_player(player)

    {:noreply, stream_delete(socket, :players, player)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp calc_final_estimate(story_id) do
    final_estimate =
      Stories.list_votes(story_id)
      |> Enum.map(& &1.estimate)
      |> Enum.frequencies()
      |> Enum.max_by(fn {_value, count} -> count end)
      |> elem(0)

    attrs =
      %{}
      |> Map.put("final_estimate", final_estimate)

    Stories.get_story!(story_id)
    |> Stories.update_story(attrs)
  end

  defp is_online?(user_id, presences) do
    Map.has_key?(presences, to_string(user_id))
  end
end
