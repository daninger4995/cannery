defmodule CanneryWeb.ErrorHTMLTest do
  use CanneryWeb.ConnCase, async: true
  import Phoenix.Template
  alias CanneryWeb.ErrorHTML

  describe "render_to_string/4" do
    test "renders 404.html" do
      assert render_to_string(ErrorHTML, "404", "html", []) =~ "Not found"
    end

    test "renders 500.html" do
      assert render_to_string(ErrorHTML, "500", "html", []) =~ "Internal server error"
    end
  end

  describe "unauthenticated error pages" do
    test "404 page shows log in link", %{conn: conn} do
      conn = get(conn, "/nonexistent-page-that-does-not-exist")
      response = html_response(conn, 404)
      assert response =~ "Not found"
      assert response =~ "Log in"
    end

    test "500 page shows log in link", %{conn: conn} do
      response =
        render_to_string(ErrorHTML, "500", "html", %{conn: conn})

      assert response =~ "Internal server error"
      assert response =~ "Log in"
    end
  end

  describe "authenticated error pages" do
    setup :register_and_log_in_user

    test "404 page shows user email instead of log in", %{
      conn: conn,
      current_user: current_user
    } do
      conn = get(conn, "/nonexistent-page-that-does-not-exist")
      response = html_response(conn, 404)
      assert response =~ "Not found"
      assert response =~ current_user.email
      refute response =~ "Log in"
    end

    test "500 page shows user email instead of log in", %{
      conn: conn,
      current_user: current_user
    } do
      response =
        conn
        |> Plug.Conn.fetch_session()
        |> then(&render_to_string(ErrorHTML, "500", "html", %{conn: &1}))

      assert response =~ "Internal server error"
      assert response =~ current_user.email
      refute response =~ "Log in"
    end
  end
end
