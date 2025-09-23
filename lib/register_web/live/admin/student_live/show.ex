defmodule RegisterWeb.Admin.StudentLive.Show do
  use RegisterWeb, :live_view
  alias Register.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    student = Accounts.get_user!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Student: #{student.email}")
     |> assign(:student, student)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="flex justify-between items-center">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Student Information
              </h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">
                Personal details and information
              </p>
            </div>
            <.link
              navigate={~p"/Admin/students"}
              class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Back to Students
            </.link>
          </div>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:p-0">
          <dl class="sm:divide-y sm:divide-gray-200">
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Email</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <%= @student.email %>
              </dd>
            </div>
            <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Role</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                  <%= String.capitalize(@student.role) %>
                </span>
              </dd>
            </div>
          </dl>
        </div>
      </div>

      <.live_component
        module={RegisterWeb.Admin.StudentProgramComponent}
        id="student-programs"
        student_id={@student.id}
      />
    </div>
    """
  end
end
