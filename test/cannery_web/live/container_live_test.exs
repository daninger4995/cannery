defmodule CanneryWeb.ContainerLiveTest do
  @moduledoc """
  Tests the containers liveviews
  """

  use CanneryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Cannery.Containers

  @moduletag :container_live_test

  @create_attrs %{
    desc: "some desc",
    location: "some location",
    name: "some name",
    type: "some type"
  }
  @update_attrs %{
    desc: "some updated desc",
    location: "some updated location",
    name: "some updated name",
    type: "some updated type"
  }
  @invalid_attrs %{desc: nil, location: nil, name: nil, type: nil}
  @type_attrs %{
    bullet_type: "some bullet_type",
    case_material: "some case_material",
    desc: "some desc",
    manufacturer: "some manufacturer",
    name: "some name",
    grains: 120
  }
  @pack_attrs %{
    notes: "some pack",
    count: 20
  }

  defp create_container(%{current_user: current_user}) do
    container = container_fixture(@create_attrs, current_user)
    [container: container]
  end

  defp create_pack(%{container: container, current_user: current_user}) do
    type = type_fixture(@type_attrs, current_user)
    {1, [pack]} = pack_fixture(@pack_attrs, type, container, current_user)

    [type: type, pack: pack]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_container]

    test "lists all containers", %{conn: conn, container: container} do
      {:ok, _index_live, html} = live(conn, ~p"/containers")
      assert html =~ "Containers"
      assert html =~ container.location
    end

    test "lists all containers in table mode", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, ~p"/containers")

      html =
        index_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"]/)
        |> render_click()

      assert html =~ "Containers"
      assert html =~ container.location
    end

    test "can search for containers", %{conn: conn, container: container} do
      {:ok, index_live, html} = live(conn, ~p"/containers")

      assert html =~ container.location

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: container.location}) =~ container.location

      assert_patch(index_live, ~p"/containers/search/#{container.location}")

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~ container.location

      assert_patch(index_live, ~p"/containers/search/something_else")

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ container.location

      assert_patch(index_live, ~p"/containers")
    end

    test "saves new container", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, ~p"/containers")

      assert index_live |> element("a", "New Container") |> render_click() =~ "New Container"
      assert_patch(index_live, ~p"/containers/new")

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(container: @create_attrs)
        |> follow_redirect(conn, ~p"/containers")

      assert html =~ "#{container.name} created successfully"
      assert html =~ "some location"
    end

    test "updates container in listing", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, index_live, _html} = live(conn, ~p"/containers")

      assert index_live |> element(~s/a[aria-label="Edit #{container.name}"]/) |> render_click() =~
               "Edit #{container.name}"

      assert_patch(index_live, ~p"/containers/edit/#{container}")

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(container: @update_attrs)
        |> follow_redirect(conn, ~p"/containers")

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} updated successfully"
      assert html =~ "some updated location"
    end

    test "clones container in listing", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, index_live, _html} = live(conn, ~p"/containers")

      html = index_live |> element(~s/a[aria-label="Clone #{container.name}"]/) |> render_click()
      assert html =~ "New Container"
      assert html =~ "some location"

      assert_patch(index_live, ~p"/containers/clone/#{container}")

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(container: @create_attrs)
        |> follow_redirect(conn, ~p"/containers")

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} created successfully"
      assert html =~ "some location"
    end

    test "clones container in listing with updates", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, index_live, _html} = live(conn, ~p"/containers")

      assert index_live |> element(~s/a[aria-label="Clone #{container.name}"]/) |> render_click() =~
               "New Container"

      assert_patch(index_live, ~p"/containers/clone/#{container}")

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(
          container: Map.merge(@create_attrs, %{location: "some updated location"})
        )
        |> follow_redirect(conn, ~p"/containers")

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} created successfully"
      assert html =~ "some updated location"
    end

    test "deletes container in listing", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, ~p"/containers")
      assert index_live |> element(~s/a[aria-label="Delete #{container.name}"]/) |> render_click()
      refute has_element?(index_live, "#container-#{container.id}")
    end
  end

  describe "Index edit tags" do
    setup [:register_and_log_in_user, :create_container]

    test "adds a tag and immediately displays it in the modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      tag = tag_fixture(%{name: "index tag"}, current_user)

      {:ok, index_live, _html} = live(conn, ~p"/containers")

      # Open edit tags modal from index
      index_live |> element(~s/a[aria-label="Tag #{container.name}"]/) |> render_click()
      assert_patch(index_live, ~p"/containers/edit_tags/#{container}")

      # Tag should not be on the container yet
      refute has_element?(index_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)

      # Add the tag
      index_live
      |> form("#add-tag-to-container-form", tag: %{tag_id: tag.id})
      |> render_submit()

      # Tag should immediately appear as a deletable tag in the modal
      assert has_element?(index_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)
      assert render(index_live) =~ "added successfully"
    end

    test "removes a tag and immediately updates the modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      tag = tag_fixture(%{name: "removable index tag"}, current_user)
      Containers.add_tag!(container, tag, current_user)

      {:ok, index_live, _html} = live(conn, ~p"/containers")

      # Open edit tags modal
      index_live |> element(~s/a[aria-label="Tag #{container.name}"]/) |> render_click()
      assert_patch(index_live, ~p"/containers/edit_tags/#{container}")

      # Tag should be shown as a deletable tag
      assert has_element?(index_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)

      # Remove the tag
      index_live
      |> element(~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)
      |> render_click()

      # Tag should immediately disappear
      refute has_element?(index_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)
      assert render(index_live) =~ "removed successfully"
    end
  end

  describe "Index edit tags updates table" do
    setup [:register_and_log_in_user, :create_container]

    test "adding a tag updates the container table behind the modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      tag = tag_fixture(%{name: "table tag"}, current_user)

      {:ok, index_live, html} = live(conn, ~p"/containers")

      # Table should not show the tag initially
      refute html =~ "table tag"

      # Open edit tags modal and add tag
      index_live |> element(~s/a[aria-label="Tag #{container.name}"]/) |> render_click()
      assert_patch(index_live, ~p"/containers/edit_tags/#{container}")

      index_live
      |> form("#add-tag-to-container-form", tag: %{tag_id: tag.id})
      |> render_submit()

      # The table behind the modal should now show the tag in the tags cell
      html = render(index_live)
      assert html =~ ~r/class="inline-block[^"]*"[^>]*>\s*table tag\s*</
      assert html =~ "added successfully"
    end

    test "removing a tag updates the container table behind the modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      tag = tag_fixture(%{name: "removeme"}, current_user)
      Containers.add_tag!(container, tag, current_user)

      {:ok, index_live, html} = live(conn, ~p"/containers")

      # Table should show the tag initially
      assert html =~ "removeme"

      # Open edit tags modal and remove tag
      index_live |> element(~s/a[aria-label="Tag #{container.name}"]/) |> render_click()
      assert_patch(index_live, ~p"/containers/edit_tags/#{container}")

      index_live
      |> element(~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)
      |> render_click()

      # The table behind the modal should no longer show the tag
      html = render(index_live)
      refute html =~ ~r/class="inline-block[^"]*"[^>]*>\s*removeme\s*</
      assert html =~ "removed successfully"
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_container]

    test "displays container", %{
      conn: conn,
      container: %{name: name, location: location} = container
    } do
      {:ok, _show_live, html} = live(conn, ~p"/container/#{container}")
      assert html =~ name
      assert html =~ location
    end

    test "updates container within modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, show_live, _html} = live(conn, ~p"/container/#{container}")

      assert show_live |> element(~s/a[aria-label="Edit #{container.name}"]/) |> render_click() =~
               "Edit #{container.name}"

      assert_patch(show_live, ~p"/container/edit/#{container}")

      assert show_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        show_live
        |> form("#container-form")
        |> render_submit(container: @update_attrs)
        |> follow_redirect(conn, ~p"/container/#{container}")

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} updated successfully"
      assert html =~ "some updated location"
    end

    test "can sort by type",
         %{conn: conn, container: container, current_user: current_user} do
      rifle_type = type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_type, container, current_user)
      shotgun_type = type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_type, container, current_user)
      pistol_type = type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_type, container, current_user)

      {:ok, index_live, html} = live(conn, ~p"/container/#{container}")

      assert html =~ "All"

      assert html =~ rifle_pack.type.name
      assert html =~ shotgun_pack.type.name
      assert html =~ pistol_pack.type.name

      index_live
      |> form(~s/form[phx-change="change_class"]/)
      |> render_change(type: %{class: :rifle})

      assert_patch(index_live, ~p"/container/#{container}?class=rifle")

      {:ok, _index_live, html} = live(conn, ~p"/container/#{container}?class=rifle")
      assert html =~ rifle_pack.type.name
      refute html =~ shotgun_pack.type.name
      refute html =~ pistol_pack.type.name

      {:ok, index_live, _html} = live(conn, ~p"/container/#{container}")

      index_live
      |> form(~s/form[phx-change="change_class"]/)
      |> render_change(type: %{class: :shotgun})

      assert_patch(index_live, ~p"/container/#{container}?class=shotgun")

      {:ok, _index_live, html} = live(conn, ~p"/container/#{container}?class=shotgun")
      refute html =~ rifle_pack.type.name
      assert html =~ shotgun_pack.type.name
      refute html =~ pistol_pack.type.name

      {:ok, index_live, _html} = live(conn, ~p"/container/#{container}")

      index_live
      |> form(~s/form[phx-change="change_class"]/)
      |> render_change(type: %{class: :pistol})

      assert_patch(index_live, ~p"/container/#{container}?class=pistol")

      {:ok, _index_live, html} = live(conn, ~p"/container/#{container}?class=pistol")
      refute html =~ rifle_pack.type.name
      refute html =~ shotgun_pack.type.name
      assert html =~ pistol_pack.type.name

      {:ok, index_live, _html} = live(conn, ~p"/container/#{container}")

      index_live
      |> form(~s/form[phx-change="change_class"]/)
      |> render_change(type: %{class: :all})

      assert_patch(index_live, ~p"/container/#{container}?class=all")

      {:ok, _index_live, html} = live(conn, ~p"/container/#{container}?class=all")
      assert html =~ rifle_pack.type.name
      assert html =~ shotgun_pack.type.name
      assert html =~ pistol_pack.type.name
    end
  end

  describe "Show edit tags" do
    setup [:register_and_log_in_user, :create_container]

    test "adds a tag and immediately displays it", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      tag = tag_fixture(%{name: "cool tag"}, current_user)

      {:ok, show_live, _html} = live(conn, ~p"/container/#{container}")

      # Open edit tags modal
      show_live |> element(~s/a[href*="edit_tags"]/) |> render_click()
      assert_patch(show_live, ~p"/container/edit_tags/#{container}")

      # Tag should not be on the container yet (no delete link for it)
      refute has_element?(show_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)

      # Add the tag
      show_live
      |> form("#add-tag-to-container-form", tag: %{tag_id: tag.id})
      |> render_submit()

      # Tag should immediately appear as a deletable tag in the modal
      assert has_element?(show_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)
      assert render(show_live) =~ "added successfully"
    end

    test "removes a tag and immediately updates the display", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      tag = tag_fixture(%{name: "removable tag"}, current_user)
      Containers.add_tag!(container, tag, current_user)

      {:ok, show_live, _html} = live(conn, ~p"/container/#{container}")

      # Tag should be visible on the show page
      assert render(show_live) =~ "removable tag"

      # Open edit tags modal
      show_live |> element(~s/a[href*="edit_tags"]/) |> render_click()
      assert_patch(show_live, ~p"/container/edit_tags/#{container}")

      # Tag should be shown as a deletable tag
      assert has_element?(show_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)

      # Remove the tag
      show_live
      |> element(~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)
      |> render_click()

      # Tag should immediately disappear without a page refresh
      refute has_element?(show_live, ~s/a[phx-click="delete"][phx-value-tag-id="#{tag.id}"]/)
      assert render(show_live) =~ "removed successfully"
    end

    test "adding a tag updates the container show page", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      tag = tag_fixture(%{name: "visible tag"}, current_user)

      {:ok, _show_live, html} = live(conn, ~p"/container/#{container}")

      # Should show "no tags" initially
      assert html =~ "No tags for this container"

      # Open edit tags modal and add tag
      {:ok, show_live, _html} = live(conn, ~p"/container/edit_tags/#{container}")

      show_live
      |> form("#add-tag-to-container-form", tag: %{tag_id: tag.id})
      |> render_submit()

      # Navigate back to show page to verify it persisted
      {:ok, _show_live, html} = live(conn, ~p"/container/#{container}")

      assert html =~ "visible tag"
      refute html =~ "No tags for this container"
    end
  end

  describe "Show with pack" do
    setup [:register_and_log_in_user, :create_container, :create_pack]

    test "displays pack",
         %{conn: conn, type: %{name: type_name}, container: container} do
      {:ok, _show_live, html} = live(conn, ~p"/container/#{container}")

      assert html =~ type_name
      assert html =~ " 20\n"
    end

    test "displays pack in table",
         %{conn: conn, type: %{name: type_name}, container: container} do
      {:ok, show_live, _html} = live(conn, ~p"/container/#{container}")

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"]/)
        |> render_click()

      assert html =~ type_name
      assert html =~ " 20\n"
    end
  end
end
