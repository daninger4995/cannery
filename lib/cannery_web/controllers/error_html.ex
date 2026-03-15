defmodule CanneryWeb.ErrorHTML do
  use CanneryWeb, :html
  alias Cannery.Accounts

  embed_templates "error_html/*"

  def render(template, assigns) do
    error_string =
      case template do
        "404.html" -> dgettext("errors", "Not found")
        "401.html" -> dgettext("errors", "Unauthorized")
        _other_path -> dgettext("errors", "Internal server error")
      end

    current_user =
      assigns[:current_user] || get_current_user_from_conn(assigns[:conn])

    assigns
    |> Map.put(:error_string, error_string)
    |> Map.put(:current_user, current_user)
    |> render_error()
  end

  defp get_current_user_from_conn(%Plug.Conn{} = conn) do
    conn
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.get_session(:user_token)
    |> case do
      token when is_binary(token) -> Accounts.get_user_by_session_token(token)
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp get_current_user_from_conn(_conn), do: nil
end
