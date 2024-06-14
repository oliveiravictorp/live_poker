defmodule LivePokerWeb.PlayerLiveTest do
  use LivePokerWeb.ConnCase

  import Phoenix.LiveViewTest
  import LivePoker.PlayersFixtures

  @create_attrs %{moderator: true, spectator: true}
  @update_attrs %{moderator: false, spectator: false}
  @invalid_attrs %{moderator: false, spectator: false}

  defp create_player(_) do
    player = player_fixture()
    %{player: player}
  end

  describe "Index" do
    setup [:create_player]

    test "lists all players", %{conn: conn, player: player} do
      {:ok, _index_live, html} = live(conn, ~p"/players")

      assert html =~ "Listing Players"
    end

    test "saves new player", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/players")

      assert index_live |> element("a", "New Player") |> render_click() =~
               "New Player"

      assert_patch(index_live, ~p"/players/new")

      assert index_live
             |> form("#player-form", player: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#player-form", player: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/players")

      html = render(index_live)
      assert html =~ "Player created successfully"
    end

    test "updates player in listing", %{conn: conn, player: player} do
      {:ok, index_live, _html} = live(conn, ~p"/players")

      assert index_live |> element("#players-#{player.id} a", "Edit") |> render_click() =~
               "Edit Player"

      assert_patch(index_live, ~p"/players/#{player}/edit")

      assert index_live
             |> form("#player-form", player: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#player-form", player: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/players")

      html = render(index_live)
      assert html =~ "Player updated successfully"
    end

    test "deletes player in listing", %{conn: conn, player: player} do
      {:ok, index_live, _html} = live(conn, ~p"/players")

      assert index_live |> element("#players-#{player.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#players-#{player.id}")
    end
  end

  describe "Show" do
    setup [:create_player]

    test "displays player", %{conn: conn, player: player} do
      {:ok, _show_live, html} = live(conn, ~p"/players/#{player}")

      assert html =~ "Show Player"
    end

    test "updates player within modal", %{conn: conn, player: player} do
      {:ok, show_live, _html} = live(conn, ~p"/players/#{player}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Player"

      assert_patch(show_live, ~p"/players/#{player}/show/edit")

      assert show_live
             |> form("#player-form", player: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#player-form", player: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/players/#{player}")

      html = render(show_live)
      assert html =~ "Player updated successfully"
    end
  end
end
