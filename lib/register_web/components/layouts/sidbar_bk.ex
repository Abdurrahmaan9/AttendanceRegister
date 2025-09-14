defmodule RegisterWeb.Layouts.SidebarBk do
  use Phoenix.Component
  import Phoenix.LiveView.Helpers

  attr :sidebar_open, :boolean, default: false
  attr :current_path, :string, required: true
  attr :myself, :any, required: true

  def sidebar(assigns) do
    ~H"""
    <div>
      <!-- Mobile sidebar backdrop -->
      <div :if={@sidebar_open} class="fixed inset-0 z-30 bg-gray-600 bg-opacity-50 lg:hidden" phx-click="toggle_sidebar" phx-target={@myself}></div>

      <!-- Sidebar -->
      <div class={
        [
          "fixed inset-y-0 left-0 z-40 w-64 bg-white shadow-lg transform transition-transform duration-300 ease-in-out lg:translate-x-0",
          if(@sidebar_open, do: "translate-x-0", else: "-translate-x-full")
        ]
        |> Enum.join(" ")
      } style="top: 64px;">
        <div class="flex flex-col h-full">
          <div class="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
            <div class="flex items-center flex-shrink-0 px-4">
              <h2 class="text-lg font-semibold text-gray-900">
                <%= case @myself.role do
                  "admin" -> "Admin Panel"
                  "lecturer" -> "Lecturer Panel"
                  "student" -> "Student Portal"
                  _ -> "Navigation"
                end %>
              </h2>
            </div>
            <nav class="mt-5 flex-1 px-2 space-y-1">
              <%= cond do %>
                <% @myself.role == "admin" -> %>
                  <!-- Admin Dashboard -->
                  <.nav_link to="/Admin/dashboard" icon="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z M8 5a2 2 0 012-2h4a2 2 0 012 2v6H8V5z" active={@current_path == "/Admin/dashboard"}>
                    Dashboard
                  </.nav_link>

                  <!-- User Management -->
                  <h3 class="px-3 mt-4 text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center">
                    <span class="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                    User Management
                  </h3>
                  <.nav_link to="/Admin/students" icon="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" active={String.starts_with?(@current_path, "/Admin/students")}>
                    Students
                  </.nav_link>

                  <!-- Admin Lecturers -->
                  <.nav_link to="/Admin/lecturers" icon="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" active={String.starts_with?(@current_path, "/Admin/lecturers")}>
                    Lecturers
                  </.nav_link>

                  <!-- Admin Users -->
                  <.nav_link to="/Admin/users" icon="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" active={@current_path == "/Admin/users"}>
                    All Users
                  </.nav_link>

                  <!-- Admin Attendance -->
                  <.nav_link to="/Admin/attendance/record" icon="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" active={@current_path == "/attendance/record"}>
                    Attendance Recording
                  </.nav_link>

                <% @myself.role == "lecturer" -> %>
                  <!-- Lecturer Dashboard -->
                  <.nav_link to="/Lecturer/dashboard" icon="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z M8 5a2 2 0 012-2h4a2 2 0 012 2v6H8V5z" active={@current_path == "/Lecturer/dashboard"}>
                    My Dashboard
                  </.nav_link>

                  <!-- My Classes -->
                  <h3 class="px-3 mt-4 text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center">
                    <span class="w-2 h-2 bg-blue-500 rounded-full mr-2"></span>
                    My Classes
                  </h3>
                  <.nav_link to="/Lecturer/classes" icon="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" active={String.starts_with?(@current_path, "/Lecturer/classes")}>
                    View Classes
                  </.nav_link>

                  <!-- Attendance -->
                  <h3 class="px-3 mt-4 text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center">
                    <span class="w-2 h-2 bg-purple-500 rounded-full mr-2"></span>
                    Attendance
                  </h3>
                  <.nav_link to="/Lecturer/attendance" icon="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" active={String.starts_with?(@current_path, "/Lecturer/attendance")}>
                    Take Attendance
                  </.nav_link>

                <% @myself.role == "student" -> %>
                  <!-- Student Dashboard -->
                  <.nav_link to="/Students/dashboard" icon="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z M8 5a2 2 0 012-2h4a2 2 0 012 2v6H8V5z" active={@current_path == "/Students/dashboard"}>
                    My Dashboard
                  </.nav_link>

                  <!-- My Classes -->
                  <h3 class="px-3 mt-4 text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center">
                    <span class="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                    My Classes
                  </h3>
                  <.nav_link to="/Students/classes" icon="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" active={String.starts_with?(@current_path, "/Students/classes")}>
                    View Schedule
                  </.nav_link>

                  <!-- My Attendance -->
                  <h3 class="px-3 mt-4 text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center">
                    <span class="w-2 h-2 bg-blue-500 rounded-full mr-2"></span>
                    My Attendance
                  </h3>
                  <.nav_link to="/Students/attendance" icon="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" active={String.starts_with?(@current_path, "/Students/attendance")}>
                    View Attendance
                  </.nav_link>

                <% true -> %>
                  <!-- Default navigation for unauthenticated users -->
                  <.nav_link to="/" icon="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" active={@current_path == "/"}>
                    Home
                  </.nav_link>
              <% end %>
            </nav>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :to, :string, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false

  slot :inner_block, required: true


  defp nav_link(assigns) do
    base_classes = "group flex items-center px-2 py-2 text-sm font-medium rounded-md"
    active_classes = if assigns.active, do: "bg-blue-50 text-blue-700", else: "text-gray-700 hover:bg-gray-50"
    icon_base_classes = "mr-3 h-5 w-5"
    icon_active_classes = if assigns.active, do: "text-blue-500", else: "text-gray-400"

    ~H"""
    <a
      href={@to}
      class={"#{base_classes} #{active_classes}"}
    >
      <svg
        class={"#{icon_base_classes} #{icon_active_classes}"}
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d={@icon}
        />
      </svg>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
