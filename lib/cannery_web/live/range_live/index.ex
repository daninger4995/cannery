defmodule CanneryWeb.RangeLive.Index do
  @moduledoc """
  Main page for range day mode, where `Pack`s can be used up.
  """

  use CanneryWeb, :live_view
  alias Cannery.{ActivityLog, ActivityLog.ShotRecord}
  alias Cannery.{Ammo, Containers}
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    socket =
      socket
      |> assign(
        class: :all,
        start_date: Date.shift(Date.utc_today(), year: -1),
        end_date: Date.utc_today(),
        search: search
      )
      |> display_shot_records()

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        class: :all,
        start_date: Date.shift(Date.utc_today(), year: -1),
        end_date: Date.utc_today(),
        search: nil
      )
      |> display_shot_records()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply,
     socket
     |> assign_class(params)
     |> apply_action(live_action, params)}
  end

  defp assign_class(socket, %{"class" => class}) when class in ~w(rifle shotgun pistol),
    do: socket |> assign(:class, String.to_existing_atom(class))

  defp assign_class(socket, _params), do: socket |> assign(:class, :all)

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_record,
         %{"id" => id}
       ) do
    socket
    |> assign(
      page_title: gettext("Record Shots"),
      pack: Ammo.get_pack!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Edit Shot Record"),
      shot_record: ActivityLog.get_shot_record!(id, current_user)
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: gettext("Record Shots"),
      shot_record: %ShotRecord{}
    )
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      page_title: gettext("Range"),
      search: params["search"],
      shot_record: nil
    )
    |> display_shot_records()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Range"),
      search: search,
      shot_record: nil
    )
    |> display_shot_records()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    {:ok, _shot_record} =
      ActivityLog.get_shot_record!(id, current_user)
      |> ActivityLog.delete_shot_record(current_user)

    prompt = dgettext("prompts", "Shot records deleted succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_records()}
  end

  def handle_event(
        "toggle_staged",
        %{"container_id" => container_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    container = Containers.get_container!(container_id, current_user)

    {:ok, _container} =
      container
      |> Containers.update_container(current_user, %{"staged" => !container.staged})

    prompt = dgettext("prompts", "Container unstaged succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_records()}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/range")}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/range/search/#{search_term}")}
  end

  def handle_event("change_class", %{"type" => %{"class" => class}}, %{assigns: assigns} = socket) do
    params = %{"class" => class}
    params = if assigns[:search], do: Map.put(params, "search", assigns.search), else: params
    {:noreply, socket |> push_patch(to: ~p"/range?#{params}")}
  end

  def handle_event(
        "change_dates",
        %{
          "dates_start" => start_date,
          "dates_end" => end_date
        },
        socket
      ) do
    socket =
      socket
      |> assign(
        start_date: start_date,
        end_date: end_date
      )
      |> display_shot_records()

    {:noreply, socket}
  end

  @spec display_shot_records(Socket.t()) :: Socket.t()
  defp display_shot_records(
         %{
           assigns: %{
             class: class,
             start_date: start_date,
             end_date: end_date,
             search: search,
             current_user: current_user
           }
         } = socket
       ) do
    shot_records =
      ActivityLog.list_shot_records(current_user,
        class: class,
        end_date: end_date,
        search: search,
        start_date: start_date
      )

    containers =
      Containers.list_containers(current_user, staged: true)
      |> Map.new(fn container = %{id: container_id} -> {container_id, container} end)

    packs = Ammo.list_packs(current_user, staged: true)
    chart_data = shot_records |> get_chart_data_for_shot_record()
    original_counts = packs |> Ammo.get_original_counts(current_user)
    cprs = packs |> Ammo.get_cprs(current_user)
    last_used_dates = packs |> ActivityLog.get_last_used_dates(current_user)
    shot_record_count = ActivityLog.get_shot_record_count!(current_user)

    socket
    |> assign(
      containers: containers,
      packs: packs,
      original_counts: original_counts,
      cprs: cprs,
      last_used_dates: last_used_dates,
      chart_data: chart_data,
      shot_records: shot_records,
      shot_record_count: shot_record_count
    )
  end

  @spec get_chart_data_for_shot_record([ShotRecord.t()]) :: [map()]
  defp get_chart_data_for_shot_record(shot_records) do
    shot_records
    |> Enum.group_by(fn %{date: date} -> date end, fn %{count: count} -> count end)
    |> Enum.map(fn {date, rounds} ->
      sum = Enum.sum(rounds)

      %{
        date: date,
        count: sum,
        label: gettext("Rounds shot: %{count}", count: sum)
      }
    end)
  end
end
