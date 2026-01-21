defmodule LivePokerWeb.GameLive.Play do
  use LivePokerWeb, :live_view

  alias LivePoker.Games
  alias LivePoker.Players
  alias LivePoker.Stories
  alias LivePoker.Stories.Story
  alias LivePoker.Presence

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :play, %{"game_id" => game_id}) do
    if connected?(socket), do: subscribe_pub_sub()

    new_story = %Story{}
    change_story = Stories.change_story(new_story)

    stories = Stories.list_stories(game_id)
    finished_stories = Stories.list_finished_stories(game_id)
    new_story_available = length(stories) - length(finished_stories)

    estimates = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, "?"]

    topic = "game:#{game_id}"
    user = socket.assigns.current_user

    LivePokerWeb.Endpoint.subscribe(topic)
    Presence.track(self(), topic, user.id, user)
    presences = Presence.list(topic)

    socket = socket |> current_votes(game_id, presences)

    {:ok, player} = Players.get_player_by_game_and_user(game_id, user.id)
    is_moderator = Players.is_moderator?(player)

    socket
    |> stream(:players, Players.list_players_by_game(game_id))
    |> stream(:moderators, Players.list_moderators_by_game(game_id))
    |> assign(
      page_title: "Play game",
      game: Games.get_game!(game_id),
      story_form: to_form(change_story),
      user_player: player,
      is_moderator: is_moderator,
      presences: presences,
      topic: topic,
      story: new_story,
      stories: stories,
      estimates: estimates,
      new_story_available: new_story_available,
      players_qtt: presences |> map_size()
    )
  end

  defp apply_action(socket, :edit_game, %{"game_id" => game_id}) do
    socket
    |> assign(
      page_title: "Edit game",
      game: Games.get_game!(game_id)
    )
  end

  defp apply_action(socket, :edit_player, %{"player_id" => player_id}) do
    socket
    |> assign(
      page_title: "Edit player",
      player: Players.get_player!(player_id)
    )
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    %{game: %{id: game_id}, topic: topic} = socket.assigns
    presences = Presence.list(topic)

    {:noreply,
     socket
     |> assign(
       presences: presences,
       players_qtt: presences |> map_size()
     )
     |> current_votes(game_id, presences)
     |> stream(:players, Players.list_players_by_game(game_id))
     |> stream(:moderators, Players.list_moderators_by_game(game_id))}
  end

  @impl true
  def handle_info({:game_changed, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:player_changed, player_changed}, socket) do
    %{game: %{id: game_id}, current_user: current_user, topic: topic} = socket.assigns

    {:ok, player} = Players.get_player_by_game_and_user(game_id, current_user.id)
    is_moderator = Players.is_moderator?(player)

    socket = socket |> players_change_lists(player_changed)

    {:noreply,
     socket
     |> stream(:players, Players.list_players_by_game(game_id))
     |> stream(:moderators, Players.list_moderators_by_game(game_id))
     |> assign(
       user_player: player,
       is_moderator: is_moderator,
       presences: Presence.list(topic)
     )}
  end

  @impl true
  def handle_info({:story_changed, _story}, socket) do
    %{game: %{id: game_id}, current_story: current_story} = socket.assigns

    {:noreply,
     socket
     |> assign(
       stories: Stories.list_stories(game_id),
       current_story: Stories.get_current_story(game_id),
       votes:
         if current_story do
           Stories.list_votes(current_story.id)
         else
           []
         end
     )
     |> stream(:players, Players.list_players_by_game(game_id))
     |> stream(:moderators, Players.list_moderators_by_game(game_id))}
  end

  @impl true
  def handle_info({:vote_changed, _vote}, socket) do
    %{game: %{id: game_id}, presences: presences} = socket.assigns

    {:noreply,
     socket
     |> current_votes(game_id, presences)
     |> stream(:players, Players.list_players_by_game(game_id))
     |> stream(:moderators, Players.list_moderators_by_game(game_id))}
  end

  @impl true
  def handle_event("validate_story", %{"story" => story_params}, socket) do
    change_story =
      socket.assigns.story
      |> Stories.change_story(story_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(story_form: to_form(change_story))}
  end

  @impl true
  def handle_event("save_story", %{"story" => story_params}, socket) do
    game = socket.assigns.game

    story_params =
      story_params
      |> Map.put("sequence_number", game.quantity_stories + 1)
      |> Map.put("game_id", game.id)

    case Stories.create_story(story_params) do
      {:ok, story} ->
        Games.update_game(game, %{} |> Map.put("quantity_stories", story.sequence_number))

        {:noreply,
         socket
         |> put_flash(:info, "Story created successfully")
         |> push_patch(to: ~p"/game/#{game.id}")}

      {:error, %Ecto.Changeset{} = change_story} ->
        {:noreply,
         socket
         |> assign(story_form: to_form(change_story))}
    end
  end

  @impl true
  def handle_event("accept_story", %{"id" => id, "game_id" => _game_id}, socket) do
    attrs =
      %{}
      |> Map.put("finished", true)

    Stories.get_story!(id)
    |> Stories.update_story(attrs)

    # {:noreply, socket |> push_patch(to: ~p"/game/#{game_id}")}
    {:noreply, assign(socket, new_story_available: 0)}
  end

  @impl true
  def handle_event("restart_story", %{"id" => id, "game_id" => _game_id}, socket) do
    Stories.delete_all_votes(id)

    attrs =
      %{}
      |> Map.put("final_estimate", nil)

    Stories.get_story!(id)
    |> Stories.update_story(attrs)

    {:noreply, socket}
  end

  @impl true
  def handle_event("reveal_cards", %{"id" => id, "game_id" => _game_id}, socket) do
    calc_final_estimate(id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_story", %{"id" => id}, socket) do
    game = socket.assigns.game
    story = Stories.get_story!(id)
    {:ok, _} = Stories.delete_story(story)

    updated_stories = Enum.reject(socket.assigns.stories, fn s -> s.id == story.id end)

    Games.update_game(game, %{} |> Map.put("quantity_stories", game.quantity_stories - 1))

    {:noreply, assign(socket, stories: updated_stories, new_story_available: 0)}
  end

  @impl true
  def handle_event(
        "estimate_vote",
        %{
          "estimate" => estimate,
          "player_id" => player_id,
          "story_id" => story_id,
          "game_id" => _game_id,
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

    presences = Presence.list(topic)

    online_votes =
      Stories.list_votes(story_id)
      |> Enum.filter(fn vote ->
        Map.has_key?(presences, to_string(vote.player.user_id))
      end)

    votes_qtt = online_votes |> length()
    players_qtt = presences |> map_size()

    if votes_qtt >= players_qtt do
      calc_final_estimate(story_id)
    end

    {:noreply,
     assign(socket,
       votes_qtt: votes_qtt,
       players_qtt: players_qtt
     )}
  end

  @impl true
  def handle_event("delete_player", %{"id" => id}, socket) do
    player = Players.get_player!(id)
    {:ok, _} = Players.delete_player(player)

    socket = push_patch(socket, to: ~p"/game/#{player.game_id}")

    {:noreply, stream_delete(socket, :players, player)}
  end

  defp current_votes(socket, game_id, presences) do
    current_story = Stories.get_current_story(game_id)

    case current_story do
      nil ->
        socket
        |> assign(
          current_story: current_story,
          votes: nil,
          votes_qtt: 0
        )

      %Story{} = current_story ->
        online_votes =
          Stories.list_votes(current_story.id)
          |> Enum.filter(fn vote ->
            Map.has_key?(presences, to_string(vote.player.user_id))
          end)

        socket
        |> assign(
          current_story: current_story,
          votes: Stories.list_votes(current_story.id),
          votes_qtt: online_votes |> length()
        )
    end
  end

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

  defp it_played?(player_id, story_id) do
    case Stories.get_vote_by_player(player_id, story_id) do
      nil -> false
      _ -> true
    end
  end

  defp players_change_lists(socket, player) do
    if player.moderator do
      socket
      |> stream_delete(:moderators, player)
    else
      socket
      |> stream_delete(:players, player)
    end
  end

  defp subscribe_pub_sub() do
    Games.subscribe_games()
    Players.subscribe_players()
    Stories.subscribe_stories()
    Stories.subscribe_votes()
  end
end
