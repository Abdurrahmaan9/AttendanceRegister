defmodule RegisterWeb.Layouts.SidebarComponent do
  use Phoenix.Component

  attr :sidebar_open, :boolean, default: false
  attr :current_path, :string, required: true
  attr :user_type, :atom, required: true
  attr :current_user, :any, default: nil

  def sidebar(assigns) do
    ~H"""
    <div>
      <!-- Sidebar overlay for mobile -->
      <div
        class={
          [
            "fixed inset-0 z-30 bg-gray-600 bg-opacity-50 transition-opacity duration-300 ease-in-out lg:hidden",
            if(@sidebar_open, do: "opacity-100", else: "opacity-0 pointer-events-none")
          ]
          |> Enum.join(" ")
        }
        phx-click="toggle_sidebar"
        phx-target="#app-layout"
      ></div>

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
              <a
              class="w-full text-lg font-semibold text-gray-900 bg-gradient-to-r from-teal-500 to-teal-600 text-white px-3 py-2 rounded-md transition-colors duration-200 text-center block"
              href="/Admin/dashboard"
              >
              Dashboard
              </a>
            </div>
            <nav class="mt-5 flex-1 px-2 space-y-1">
              <%= case @user_type do %>
              <% :admin -> %>
              <!-- Admin links -->
              <div class="mb-4">
                <div class="mt-2 space-y-1">
                  <div class="space-y-1">
                    <button
                      type="button"
                      data-dropdown-target="user-mgmt"
                      aria-expanded="false"
                      class="group w-full flex items-center justify-between px-2 py-2 text-sm font-medium rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      <span class="flex items-center">
                        <svg class="mr-3 h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                        </svg>
                        User Management
                      </span>
                      <svg class="h-4 w-4 text-gray-400 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                      </svg>
                    </button>
                    <div id="user-mgmt-dropdown" class="dropdown-content hidden ml-8 space-y-1">
                      <a href="/Admin/users" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">All Users</a>
                      <a href="/Admin/students" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">Students</a>
                      <a href="/Admin/lecturers" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">Lecturers</a>
                      <a href="/Admin/admins-staff" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">Admins & Staff</a>
                    </div>
                  </div>
                </div>
              </div>

              <div class="mb-4">
                <h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center">
                  <span class="w-2 h-2 bg-blue-500 rounded-full mr-2"></span>
                  Academic Management
                </h3>
                <div class="mt-2 space-y-1">
                  <.nav_link to="/Admin/programs" icon="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" active={String.starts_with?(@current_path, "/Admin/programs")}>
                    Programs
                  </.nav_link>
                  <.nav_link to="/Admin/courses" icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" active={String.starts_with?(@current_path, "/courses")}>
                    Course Management
                  </.nav_link>

                  <div class="mt-2 space-y-1">
                  <%= if @current_user do %>
                    <.nav_link to={"/Admin/students/#{@current_user.id}"} icon="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" active={@current_path == "/Admin/students/#{@current_user.id}"}>
                      My Profile
                    </.nav_link>
                  <% end %>
                  <div class="space-y-1">
                    <button
                      type="button"
                      data-dropdown-target="system-mgmt"
                      aria-expanded="false"
                      class="group w-full flex items-center justify-between px-2 py-2 text-sm font-medium rounded-md text-gray-700 hover:bg-gray-50"
                    >
                      <span class="flex items-center">
                        <svg class="mr-3 h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                        </svg>
                        Attendance Management
                      </span>
                      <svg class="h-4 w-4 text-gray-400 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                      </svg>
                    </button>
                    <div id="system-mgmt-dropdown" class="dropdown-content hidden ml-8 space-y-1">
                      <a href="/Admin/qr-codes" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">QR Code Management</a>
                      <a href="/Admin/otp-management" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">OTP Management</a>
                      <a href="/Admin/attendance/record" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">Attendance Records</a>
                      <a href="/Admin/attendance/view" class="text-gray-700 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md">Attendance View</a>
                    </div>
                  </div>
                </div>
              </div>
                <h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center mt-4">
                  <span class="w-2 h-2 bg-blue-500 rounded-full mr-2"></span>
                  Reports & Analytics
                </h3>
                <div class="mt-2 space-y-1">
                  <.nav_link to="/Admin/reports" icon="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" active={String.starts_with?(@current_path, "/reports")}>
                    Reports
                  </.nav_link>
                  <.nav_link to="/Admin/audit-logs" icon="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" active={String.starts_with?(@current_path, "/audit-logs")}>
                    Audit Logs
                  </.nav_link>
                </div>
                <div>
                <.nav_link to="/Admin/users/settings" icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" active={@current_path == "/Admin/users/settings"}>
                  Change Password
                </.nav_link>
                <.nav_link
                  to="/users/log_out"
                  method="delete"
                  icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                  active={@current_path == "/users/log_out"}
                >
                  Log out
                </.nav_link>
                </div>
              </div>

              <% :student -> %>
                <!-- Student links -->
                  <.nav_link to="/Students/attendance" icon="M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" active={@current_path == "/Students/attendance/view"}>
                    Attendance View
                  </.nav_link>
                  <.nav_link to="/Students/courses" icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" active={@current_path == "/Students/courses"}>
                    Course View
                  </.nav_link>
                  <.nav_link to="/Students/qr-codes" icon="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" active={@current_path == "/Students/scan-register"}>
                    Scan Register
                  </.nav_link>
                  <.nav_link to="/Students/scan" icon="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" active={@current_path == "/Students/scan"}>
                    Scan QR Code
                  </.nav_link>
                  <.nav_link to="/Students/otp-management" icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" active={@current_path == "/Students/enter-register-otp"}>
                    Enter Register OTP
                  </.nav_link>
                  <.nav_link to="/Students/users/settings" icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" active={@current_path == "/Students/users/settings"}>
                    Change Password
                  </.nav_link>
                  <.nav_link
                    to="/users/log_out"
                    method="delete"
                    icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                    active={@current_path == "/users/log_out"}
                  >
                    Log out
                  </.nav_link>

              <% :lecturer -> %>
                  <!-- Lecturer links -->
                  <.nav_link to="/Lecturer/attendance/view" icon="M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" active={@current_path == "/Lecturer/attendance/view"}>
                    Attendance View
                  </.nav_link>
                  <.nav_link to="/Lecturer/otp-management" icon="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2" active={@current_path == "/Lecturer/otp-management"}>
                    Manage OTP
                  </.nav_link>
                  <.nav_link to="/Lecturer/qr-codes" icon="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2" active={@current_path == "/Lecturer/qr-codes"}>
                    Manage QR Codes
                  </.nav_link>
                  <.nav_link to="/Lecturer/users/settings" icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" active={@current_path == "/users/settings"}>
                    Change Password
                  </.nav_link>
                  <.nav_link
                    to="/users/log_out"
                    method="delete"
                    icon="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                    active={@current_path == "/users/log_out"}
                  >
                    Log out
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
    assigns = assign(assigns, :base_classes, "group flex items-center px-2 py-2 text-sm font-medium rounded-md")
    assigns = assign(assigns, :active_classes, if(assigns.active, do: "bg-blue-50 text-blue-700", else: "text-gray-700 hover:bg-gray-50"))
    assigns = assign(assigns, :icon_base_classes, "mr-3 h-5 w-5")
    assigns = assign(assigns, :icon_active_classes, if(assigns.active, do: "text-blue-500", else: "text-gray-400"))

    ~H"""
    <a
      href={@to}
      class={"#{@base_classes} #{@active_classes}"}
    >
      <svg
        class={"#{@icon_base_classes} #{@icon_active_classes}"}
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
