defmodule RegisterWeb.Components.Layouts.Dropdown do
  use Phoenix.Component
  import Phoenix.HTML

  attr :title, :string, required: true
  attr :icon, :string, required: false
  attr :active, :boolean, default: false
  attr :class, :string, default: ""

  slot :item, required: true do
    attr :to, :string, required: true
    attr :active, :boolean
  end

  def dropdown(assigns) do
    ~H"""
    <div class={"space-y-1 dropdown-container" <> if(@class != "", do: " " <> @class, else: "")}>
      <button
        type="button"
        class={
          "group w-full flex items-center px-3 py-2 text-sm font-medium rounded-md"
          if @active, do: "bg-gray-100 text-gray-900", else: "text-gray-700 hover:bg-gray-50 hover:text-gray-900"
        }
        data-dropdown-target={String.downcase(@title) |> String.replace(" ", "-")}
        onclick="event.stopPropagation(); this.setAttribute('phx-click', 'noop');"
      >
        <svg
          class={
            "mr-3 h-5 w-5 flex-shrink-0"
            if @active do
              "text-gray-500"
            else
              "text-gray-400 group-hover:text-gray-500"
            end
          }
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke_linecap="round"
            stroke_linejoin="round"
            stroke_width="2"
            d={@icon}
          />
        </svg>
        <span class="flex-1 text-left"><%= @title %></span>
        <svg
          class={
            "ml-3 h-5 w-5 flex-shrink-0 transform transition-transform duration-200"
            if @active do
              "text-gray-400 rotate-90"
            else
              "text-gray-300 group-hover:text-gray-400"
            end
          }
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path fill_rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip_rule="evenodd" />
        </svg>
      </button>

      <div
        id={"#{String.downcase(@title) |> String.replace(" ", "-")}-dropdown"}
        class={"space-y-1 pl-11 dropdown-content"
          if @active, do: " block", else: " hidden"
        }
        aria-labelledby={"#{String.downcase(@title) |> String.replace(" ", "-")}-button"}
      >
      <%= for item <- @item do %>
        <.link
          patch={item[:to]}
          class={
            "group flex w-full items-center rounded-md py-2 pl-3 pr-2 text-sm font-medium"
            if Map.get(item, :active, false) do
              "bg-gray-100 text-gray-900"
            else
              "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
            end
          }
        >
          <span class="truncate"><%= render_slot(item) %></span>
        </.link>
      <% end %>
      </div>
    </div>
    """
  end
end
