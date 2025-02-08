defmodule LivePokerWeb.GameLive.PlayerComponent do
  use LivePokerWeb, :live_component

  alias LivePoker.Players

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage player records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="player-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:moderator]} type="checkbox" label="Moderator" />
        <%!--<.input field={@form[:spectator]} type="checkbox" label="Spectator" />--%>
        <:actions>
          <.button phx-disable-with="Saving...">Save player</.button>
          <.button
            phx-click={JS.push("delete_player", value: %{id: @player.id})}
            data-confirm="Are you sure?"
            phx-disable-with="Deleting..."
          >
            Delete player
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{player: player} = assigns, socket) do
    changeset = Players.change_player(player)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"player" => player_params}, socket) do
    changeset =
      socket.assigns.player
      |> Players.change_player(player_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"player" => player_params}, socket) do
    save_player(socket, socket.assigns.action, player_params)
  end

  defp save_player(socket, :edit_player, player_params) do
    case Players.update_player(socket.assigns.player, player_params) do
      {:ok, player} ->
        notify_parent({:saved, player})

        {:noreply,
         socket
         |> put_flash(:info, "Player updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_player(socket, :new, player_params) do
    params =
      player_params
      |> Map.put("user_id", socket.assigns.user_id)

    case Players.create_player(params) do
      {:ok, player} ->
        notify_parent({:saved, player})

        {:noreply,
         socket
         |> put_flash(:info, "Player created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
