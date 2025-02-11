defmodule LivePokerWeb.GameLive.FormComponent do
  use LivePokerWeb, :live_component

  alias LivePoker.Games
  alias LivePoker.Players

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>You can start inviting estimators after you have created the game.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="game-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Game name" />
        <.input field={@form[:description]} type="text" label="Game description (optional)" />
        <:actions>
          <.button phx-disable-with="Saving...">Save game</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{game: game} = assigns, socket) do
    changeset = Games.change_game(game)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"game" => game_params}, socket) do
    changeset =
      socket.assigns.game
      |> Games.change_game(game_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"game" => game_params}, socket) do
    save_game(socket, socket.assigns.action, game_params)
  end

  defp save_game(socket, :edit, game_params) do
    edit_game(socket, game_params)
  end

  defp save_game(socket, :edit_game, game_params) do
    edit_game(socket, game_params)
  end

  defp save_game(socket, :new, game_params) do
    game_params =
      game_params
      |> Map.put("quantity_stories", 0)

    case Games.create_game(game_params) do
      {:ok, game} ->
        %{}
        |> Map.put("user_id", socket.assigns.user_id)
        |> Map.put("game_id", game.id)
        |> Map.put("moderator", true)
        |> Players.create_player()

        {:noreply,
         socket
         |> put_flash(:info, "Game created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp edit_game(socket, game_params) do
    case Games.update_game(socket.assigns.game, game_params) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> put_flash(:info, "Game updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
