defmodule GenexRemoteWeb.Components.Feeds do
  @moduledoc """
  Functional Components for building an Feed list
  """
  use Phoenix.Component

  @doc """
  Shows an activity feed
  """
  attr :for, :list, required: true
  slot(:item)

  def activity(assigns) do
    ~H"""
    <div class="flow-root">
      <ul role="list" class="-mb-8">
        <%= for {data, idx} <- Enum.with_index(@for) do %>
          <%= render_slot(@item, Map.merge(data, %{index: idx})) %>
        <% end %>
      </ul>
    </div>
    """
  end

  @doc """
  An item in the activity feed
  """
  attr :icon, :atom, default: :user
  attr :icon_color, :string, default: "bg-gray-200"
  attr :activity, :string, required: true
  attr :timestamp, :any, default: DateTime.to_string(DateTime.utc_now())
  attr :last, :boolean, default: false

  def activity_item(assigns) do
    ~H"""
    <li>
      <div class="relative pb-8">
        <%= if !@last do %>
          <span
            class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200 last:hidden"
            aria-hidden="true"
          >
          </span>
        <% end %>
        <div class="relative flex space-x-3">
          <div>
            <span class={"h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white " <> @icon_color}>
              <.show_icon icon={@icon} />
            </span>
          </div>
          <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
            <div>
              <p class="text-sm text-gray-500">
                <%= @activity %>
                <!-- Applied to <a href="#" class="font-medium text-gray-900">Front End Developer</a> -->
              </p>
            </div>
            <div class="whitespace-nowrap text-right text-sm text-gray-500">
              <.show_datetime timestamp={@timestamp} />
            </div>
          </div>
        </div>
      </div>
    </li>
    """
  end

  attr :timestamp, :any, required: true

  defp show_datetime(assigns) do
    assigns = assign(assigns, :formatted_timestamp, format_timestamp(assigns.timestamp))

    ~H"""
    <time datetime={@formatted_timestamp}><%= @formatted_timestamp %></time>
    """
  end

  defp format_timestamp(timestamp) do
    timestamp =
      case timestamp do
        %NaiveDateTime{} = dt -> NaiveDateTime.to_string(dt)
        dt -> dt
      end

    case DateTime.from_iso8601(timestamp <> "Z") do
      {:ok, dt, _} -> Calendar.strftime(dt, "%b %d %Y %H:%M:%S")
      _ -> "Invalid date"
    end
  end

  defp show_icon(assigns) do
    case assigns.icon do
      :user -> ~H[<Heroicons.user mini class="text-white" />]
      _ -> ~H[<Heroicons.arrow_right mini class="text-white" />]
    end
  end
end
