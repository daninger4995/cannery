defmodule CanneryWeb.ErrorHTML do
  use CanneryWeb, :html

  embed_templates "error_html/*"

  def render(template, _assigns) do
    error_string =
      case template do
        "404.html" -> dgettext("errors", "Not found")
        "401.html" -> dgettext("errors", "Unauthorized")
        _other_path -> dgettext("errors", "Internal server error")
      end

    render_error(%{error_string: error_string})
  end

  defp render_error(assigns) do
    ~H"""
    <p>{@error_string}</p>
    """
  end
end
