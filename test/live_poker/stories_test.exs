defmodule LivePoker.StoriesTest do
  use LivePoker.DataCase

  alias LivePoker.Stories

  describe "stories" do
    alias LivePoker.Stories.Story

    import LivePoker.StoriesFixtures

    @invalid_attrs %{name: nil, finished: nil, description: nil, sequence_number: nil, final_estimate: nil}

    test "list_stories/0 returns all stories" do
      story = story_fixture()
      assert Stories.list_stories() == [story]
    end

    test "get_story!/1 returns the story with given id" do
      story = story_fixture()
      assert Stories.get_story!(story.id) == story
    end

    test "create_story/1 with valid data creates a story" do
      valid_attrs = %{name: "some name", finished: true, description: "some description", sequence_number: 42, final_estimate: 42}

      assert {:ok, %Story{} = story} = Stories.create_story(valid_attrs)
      assert story.name == "some name"
      assert story.finished == true
      assert story.description == "some description"
      assert story.sequence_number == 42
      assert story.final_estimate == 42
    end

    test "create_story/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stories.create_story(@invalid_attrs)
    end

    test "update_story/2 with valid data updates the story" do
      story = story_fixture()
      update_attrs = %{name: "some updated name", finished: false, description: "some updated description", sequence_number: 43, final_estimate: 43}

      assert {:ok, %Story{} = story} = Stories.update_story(story, update_attrs)
      assert story.name == "some updated name"
      assert story.finished == false
      assert story.description == "some updated description"
      assert story.sequence_number == 43
      assert story.final_estimate == 43
    end

    test "update_story/2 with invalid data returns error changeset" do
      story = story_fixture()
      assert {:error, %Ecto.Changeset{}} = Stories.update_story(story, @invalid_attrs)
      assert story == Stories.get_story!(story.id)
    end

    test "delete_story/1 deletes the story" do
      story = story_fixture()
      assert {:ok, %Story{}} = Stories.delete_story(story)
      assert_raise Ecto.NoResultsError, fn -> Stories.get_story!(story.id) end
    end

    test "change_story/1 returns a story changeset" do
      story = story_fixture()
      assert %Ecto.Changeset{} = Stories.change_story(story)
    end
  end

  describe "votes" do
    alias LivePoker.Stories.Vote

    import LivePoker.StoriesFixtures

    @invalid_attrs %{estimate: nil}

    test "list_votes/0 returns all votes" do
      vote = vote_fixture()
      assert Stories.list_votes() == [vote]
    end

    test "get_vote!/1 returns the vote with given id" do
      vote = vote_fixture()
      assert Stories.get_vote!(vote.id) == vote
    end

    test "create_vote/1 with valid data creates a vote" do
      valid_attrs = %{estimate: 42}

      assert {:ok, %Vote{} = vote} = Stories.create_vote(valid_attrs)
      assert vote.estimate == 42
    end

    test "create_vote/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stories.create_vote(@invalid_attrs)
    end

    test "update_vote/2 with valid data updates the vote" do
      vote = vote_fixture()
      update_attrs = %{estimate: 43}

      assert {:ok, %Vote{} = vote} = Stories.update_vote(vote, update_attrs)
      assert vote.estimate == 43
    end

    test "update_vote/2 with invalid data returns error changeset" do
      vote = vote_fixture()
      assert {:error, %Ecto.Changeset{}} = Stories.update_vote(vote, @invalid_attrs)
      assert vote == Stories.get_vote!(vote.id)
    end

    test "delete_vote/1 deletes the vote" do
      vote = vote_fixture()
      assert {:ok, %Vote{}} = Stories.delete_vote(vote)
      assert_raise Ecto.NoResultsError, fn -> Stories.get_vote!(vote.id) end
    end

    test "change_vote/1 returns a vote changeset" do
      vote = vote_fixture()
      assert %Ecto.Changeset{} = Stories.change_vote(vote)
    end
  end
end
