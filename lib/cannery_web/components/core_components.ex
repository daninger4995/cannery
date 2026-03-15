defmodule CanneryWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use CanneryWeb, :verified_routes
  use Gettext, backend: CanneryWeb.Gettext
  use Phoenix.Component
  import CanneryWeb.HTMLHelpers
  alias Cannery.{Accounts, Accounts.Invite, Accounts.User}
  alias Cannery.{Ammo, Ammo.Pack}
  alias Cannery.{Containers.Container, Containers.Tag}
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS

  embed_templates "core_components/*"

  attr :title_content, :string, default: nil
  attr :current_user, User, default: nil

  def topbar(assigns)

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: true
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="hidden relative z-50"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 transition-opacity backdrop-blur-sm bg-[#2a2a2aee]"
        aria-hidden="true"
      />
      <div
        class="overflow-y-auto fixed inset-0"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex justify-center items-center min-h-full">
          <div class="p-4 w-full max-w-3xl sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="hidden"
            >
              <div
                class="p-0.5 rounded-2xl bg-radial-[at_25%_75%] bg-white"
                style="filter: drop-shadow(#ffffff15 0rem 0rem 0.3rem)"
              >
                <div class="relative p-14 rounded-2xl shadow-lg bg-white border-2">
                  <div class="absolute right-5 top-6">
                    <button
                      phx-click={JS.exec("data-cancel", to: "##{@id}")}
                      type="button"
                      class="flex-none p-3 -m-3 opacity-20 hover:opacity-40"
                      aria-label={gettext("close")}
                    >
                      <.icon
                        name="x-mark"
                        class="w-5 h-5 text-zinc-500 hover:text-zinc-800 transition-all duration-500 ease-in-out"
                      />
                    </button>
                  </div>
                  <div id={"#{@id}-content"}>
                    {render_slot(@inner_block)}
                  </div>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="fixed bottom-4 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1 bg-[#333333] text-[#fafafa] ring-[#fafafa] fill-[#fafafa]"
      {@rest}
    >
      <p :if={@title} class="flex gap-1.5 items-center text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="information-circle" class="size-4" />
        <.icon :if={@kind == :error} name="exclamation-circle" class="size-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="absolute top-1 right-1 p-2 group" aria-label={gettext("close")}>
        <.icon name="x-mark" class="opacity-40 size-5 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="arrow-path" class="ml-1 w-3 h-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="arrow-path" class="ml-1 w-3 h-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class={"flex flex-col mt-4 space-y-2 #{@class}"}>
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="col-span-full flex gap-6 items-center mx-auto mt-2">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :style, :atom, default: :white, values: [:white, :red, :gray, :primary]
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "px-4 py-1.5 text-sm font-semibold leading-6 rounded-lg cursor-pointer phx-submit-loading:opacity-75 transition duration-300 ease-in-out",
        button_style_classes(@style),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp button_style_classes(:white) do
    "text-gray-800 bg-white/85 hover:bg-white/95 active:text-gray-900 drop-shadow-white hover:drop-shadow-white-bright"
  end

  defp button_style_classes(:red) do
    "text-white bg-soft-red-700 hover:bg-soft-red-800"
  end

  defp button_style_classes(:gray) do
    "text-white bg-gray-600 hover:bg-gray-700"
  end

  defp button_style_classes(:primary) do
    "text-gray-800 bg-primary/85 hover:bg-primary/95 active:text-black drop-shadow-primary hover:drop-shadow-primary-bright"
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :hidden_label, :boolean, default: false
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week radio hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil
  attr :container_class, :any, default: nil

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step class)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={@container_class}>
      <label class="flex gap-4 leading-6 text-zinc-900 items-center justify-center text-sm">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          phx-update="ignore"
          class={[
            "rounded-sm focus:ring-0",
            @errors == [] && "border-gray-300 focus:border-gray-100",
            @errors != [] && "border-red-300 focus:border-red-400",
            (@rest[:disabled] || @rest[:readonly]) &&
              "bg-gray-700 text-white hover:cursor-not-allowed",
            @class
          ]}
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "radio"} = assigns) do
    ~H"""
    <div class={@container_class}>
      <.label for={@id} class={@hidden_label && "sr-only"}>{@label}</.label>
      <div>
        <div class="py-2 flex flex-col space-y-2 sm:space-y-0 sm:space-x-4 sm:flex-row sm:items-center">
          <div :for={{option_value, option_label} <- @options} class="flex items-center">
            <input
              type="radio"
              id={"#{@id}_#{option_value}"}
              name={@name}
              value={option_value}
              phx-update="ignore"
              checked={@value == option_value}
              class={[
                "w-4 h-4 mr-2 text-primary-600 bg-gray-100 border-gray-300 focus:ring-primary-500 dark:focus:ring-primary-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600",
                @errors == [] && "border-gray-300 focus:border-gray-100",
                @errors != [] && "border-red-300 focus:border-red-400",
                (@rest[:disabled] || @rest[:readonly]) &&
                  "bg-gray-700 text-white hover:cursor-not-allowed",
                @class
              ]}
              {@rest}
            />
            <.label for={"#{@id}_#{option_value}"} class={@hidden_label && "sr-only"}>
              {option_label}
            </.label>
          </div>
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class={@container_class}>
      <.label for={@id} class={[@hidden_label && "sr-only", "pl-2"]}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[
          "block w-full rounded-lg border bg-white/5 px-2 py-1 text-white focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-gray-300 focus:border-gray-100",
          @errors != [] && "border-red-300 focus:border-red-400",
          (@rest[:disabled] || @rest[:readonly]) && "bg-gray-700 text-white hover:cursor-not-allowed",
          @class
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class={@container_class}>
      <.label for={@id} class={@hidden_label && "sr-only"}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "px-2 py-1 block w-full rounded-lg border text-white focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-gray-300 focus:border-gray-100",
          @errors != [] && "border-red-300 focus:border-red-400",
          (@rest[:disabled] || @rest[:readonly]) && "bg-gray-700 text-white hover:cursor-not-allowed",
          @class
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class={@container_class}>
      <.label for={@id} class={@hidden_label && "sr-only"}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "px-2 py-1 block w-full rounded-lg border text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-gray-300 focus:border-gray-100",
          @errors != [] && "border-red-300 focus:border-red-400",
          (@rest[:disabled] || @rest[:readonly]) && "bg-gray-700 text-white hover:cursor-not-allowed",
          @class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a searchbar.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, required: true
  attr :value, :any
  attr :errors, :list, default: []
  attr :class, :string, default: nil
  attr :container_class, :any, default: "flex items-center grow"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step class)

  def searchbar(assigns) do
    ~H"""
    <div class={@container_class}>
      <label for={@id} class="sr-only block text-sm leading-6 text-white">
        {@label}
      </label>
      <input
        type="text"
        name={@name}
        id={@id}
        value={@value}
        class={[
          "px-2 py-1 flex grow w-full rounded-lg border text-white focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-gray-300 focus:border-gray-100",
          @errors != [] && "border-red-300 focus:border-red-400",
          (@rest[:disabled] || @rest[:readonly]) && "bg-gray-700 text-white hover:cursor-not-allowed",
          @class
        ]}
        role="search"
        placeholder={@label}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class={@class || "block text-sm leading-6 text-zinc-900"}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <div class="flex gap-3 mt-3 text-sm leading-6 text-red-300">
      <.icon name="exclamation-circle" class="flex-none mt-0.5 size-5" />
      <p class="text-red-300">{render_slot(@inner_block)}</p>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg leading-8 text-white">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-white">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm leading-6 text-left text-white">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative text-sm leading-6 text-white border-t border-gray-200 divide-y divide-gray-100"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class={[
                  "absolute right-0 text-white -inset-y-px transition-[background-color] duration-300 ease-in-out group-hover:bg-gray-700",
                  if(i == 0, do: "-left-4 sm:rounded-l-xl", else: "left-0")
                ]} />
                <span class="relative">
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative p-0 w-14">
              <div class="relative py-4 text-sm font-medium text-right whitespace-nowrap">
                <span class="absolute left-0 -inset-y-px -right-4 transition-[background-color] duration-300 ease-in-out group-hover:bg-gray-700 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative flex ml-4 leading-6 text-white hover:text-white"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-gray-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="flex-none w-1/4 text-white">{item.title}</dt>
          <dd class="text-white">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" class="size-5" />
      <.icon name="hero-arrow-path" class="ml-1 size-4 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-5"

  def icon(assigns) do
    ~H"""
    <Heroicons.icon name={@name} class={@class} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      time: 300,
      transition: {
        "transition-all transform ease-out duration-300",
        "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
        "opacity-100 translate-y-0 sm:scale-100"
      }
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      time: 200,
      transition: {
        "transition-all transform ease-in duration-200",
        "opacity-100 translate-y-0 sm:scale-100",
        "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
      }
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(CanneryWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CanneryWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  def glow(color \\ :white)

  def glow(:white),
    do:
      "transform-shadow duration-300 ease-in-out text-white drop-shadow-white hover:drop-shadow-white-bright"

  def glow(:primary),
    do:
      "transform-shadow duration-300 ease-in-out text-primary drop-shadow-primary hover:drop-shadow-primary-bright"

  @doc """
  Renders a code block.

  ## Examples

      <.code>
        <%= "Hello World!" %>
      </.code>
  """
  slot :inner_block, required: true

  def code(assigns) do
    ~H"""
    <div class="inline-flex rounded bg-gray-900 px-1 py-0.5 font-mono text-white">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a copy to clipboard button.

  ## Examples

      <.copy_to_clipboard text="Text to copy" />
  """
  attr :text, :string, required: true
  attr :id, :string, default: "copy-to-clipboard-#{System.unique_integer()}"
  slot :inner_block, required: true

  def copy_to_clipboard(assigns) do
    ~H"""
    <div class="inline-flex space-x-2">
      <.code>{render_slot(@inner_block)}</.code>
      <button
        type="button"
        id={@id}
        class="flex items-center gap-2 text-gray-400 hover:text-gray-500"
        phx-click={JS.dispatch("cannery:copy-to-clipboard", to: "##{@id}", detail: %{text: @text})}
      >
        <.icon name="clipboard" class="w-4 h-4" />
        <span
          id={"#{@id}-success"}
          class="transition-opacity ease-in-out duration-300 opacity-0 text-xs text-green-500"
        >
          {gettext("Copied!")}
        </span>
        <span
          id={"#{@id}-failure"}
          class="transition-opacity ease-in-out duration-300 opacity-0 text-xs text-red-500"
        >
          {gettext("Failed!")}
        </span>
      </button>
    </div>
    """
  end

  attr :action, :string, required: true
  attr :value, :boolean, required: true
  attr :id, :string, default: nil
  slot(:inner_block)

  @doc """
  A toggle button element that can be directed to a liveview or a
  live_component's `handle_event/3`.

  ## Examples

  <.toggle_button action="my_liveview_action" value={@some_value}>
    <span>Toggle me!</span>
  </.toggle_button>
  <.toggle_button action="my_live_component_action" target={@myself} value={@some_value}>
    <span>Whatever you want</span>
  </.toggle_button>
  """
  def toggle_button(assigns)

  attr :container, Container, required: true
  attr :current_user, User, required: true
  slot(:tag_actions)
  slot(:inner_block)

  @spec container_card(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
  def container_card(assigns)

  attr :tag, Tag, required: true
  slot(:inner_block, required: true)

  def tag_card(assigns)

  attr :tag, Tag, required: true

  def simple_tag_card(assigns)

  attr :pack, Pack, required: true
  attr :current_user, User, required: true
  attr :original_count, :integer, default: nil
  attr :cpr, :integer, default: nil
  attr :last_used_date, Date, default: nil
  attr :container, Container, default: nil
  slot(:inner_block)

  def pack_card(assigns)

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)

  attr :user, User, required: true
  slot(:inner_block, required: true)

  def user_card(assigns)

  attr :invite, Invite, required: true
  attr :use_count, :integer, default: nil
  attr :current_user, User, required: true
  slot(:inner_block)
  slot(:code_actions)

  def invite_card(assigns)

  attr :content, :string, required: true
  attr :filename, :string, default: "qrcode", doc: "filename without .png extension"
  attr :image_class, :string, default: "w-64 h-max"
  attr :width, :integer, default: 384, doc: "width of png to generate"

  @doc """
  Creates a downloadable QR Code element
  """
  def qr_code(assigns)

  attr :id, :string, required: true
  attr :date, :any, required: true, doc: "A `Date` struct or nil"

  @doc """
  Phoenix.Component for a <date> element that renders the Date in the user's
  local timezone
  """
  def date(assigns)

  attr :id, :string, required: true
  attr :datetime, :any, required: true, doc: "A `DateTime` struct or nil"

  @doc """
  Phoenix.Component for a <time> element that renders the DateTime in the
  user's local timezone
  """
  def datetime(assigns)

  attr :name, :string, required: true

  attr :start_date, :string,
    default: Date.utc_today() |> Date.shift(year: -1) |> Date.to_iso8601()

  attr :end_date, :string, default: Date.utc_today() |> Date.to_iso8601()

  @doc """
  Phoenix.Component for an element that generates date fields for a range
  """
  def date_range(assigns)

  @spec cast_datetime(DateTime.t() | nil) :: String.t()
  defp cast_datetime(%DateTime{} = datetime) do
    datetime |> DateTime.to_iso8601(:extended)
  end

  defp cast_datetime(_datetime), do: ""
end
