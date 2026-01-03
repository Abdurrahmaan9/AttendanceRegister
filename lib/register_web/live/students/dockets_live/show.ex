defmodule RegisterWeb.Students.DocketsLive.Show do
  use RegisterWeb, :live_view
  alias Register.Dockets
  import Base

  @url "/Students/dockets"

  @impl true
  def mount(%{"type" => docket_type}, session, socket) do
    current_user = get_session_user(session)

    socket =
      socket
      |> assign(:current_path, @url)
      |> assign(:current_user, current_user)
      |> assign(:sidebar_open, false)
      |> assign(:docket_type, docket_type)

    if current_user != nil and docket_type in ["cat1", "cat2", "exam"] do
      case Dockets.generate_docket_html(current_user.id, docket_type, "/images/CUZ_Logo.png") do
        {:ok, docket_data} ->
          {:ok,
           socket
           |> assign(:docket_data, docket_data)
           |> assign(:docket_name, Dockets.docket_type_name(docket_type))
           |> assign(:semester_info, Dockets.get_semester_info(docket_type))}

        _error ->
          {:ok, push_navigate(socket, to: "/Students/dockets")}
      end
    else
      {:ok, push_navigate(socket, to: "/Students/dockets")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="min-h-screen bg-gray-100 py-8 px-4">
        <div class="max-w-4xl mx-auto bg-white shadow-lg">
          <!-- Header Section -->
          <div class="p-8 border-b-2 border-gray-300">
            <!-- Logo and Title -->
            <div class="flex justify-between items-start mb-6">
              <div class="w-20 h-20 bg-gray-200 rounded flex items-center justify-center overflow-hidden">
                <img src="/images/CUZ_logo.png" alt="CUZ Logo" class="w-full h-full object-contain" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div class="text-xs text-black-500" style="display:none;">LOGO</div>
              </div>
            </div>

            <div class="text-center flex-1">
              <h1 class="text-2xl font-bold">Cavendish University Zambia Ltd.</h1>
              <div class="grid grid-cols-2 gap-4 text-sm border-t pt-4">
              </div>
              <p class="text-2xl font-bold mt-2">Faculty of Business and Information Technology</p>
              <p class="text-2xl font-bold"><%= @docket_data.student_program.program.name %></p>
              <p class="text-2xl font-bold text-black-600 mt-2"><%= @docket_name %></p>
            </div>

            <!-- Metadata -->
            <div class="flex items-center justify-between">
              <p class="font-semibold">Date Issued:<span class="font-normal ml-2"><%= @docket_data.date_issued %></span></p>
              <p class="font-semibold text-right"><span class="font-normal ml-2"><%= @docket_data.document_id %></span></p>
            </div>

            <!-- Student Info -->
            <div>
              <p class="font-semibold">Student Name:<span class="font-normal ml-2"><%= String.upcase(@docket_data.user.first_name <> " " <> @docket_data.user.last_name) %></span></p>
              <p class="font-semibold mt-2">Student Number:<span class="font-normal ml-2"><%= @docket_data.user.email %></span></p>
            </div>
          </div>

          <!-- Courses Table Section -->
          <div class="p-8">
            <table class="w-full">
              <thead>
                <tr class="bg-gray-300">
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold">Code</th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold">Module</th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold">Date Time</th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold">Venue</th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold">INVIGILATOR'S SIGNATURE</th>
                </tr>
                <tr>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold"></th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold"></th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold"><%= @semester_info %></th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold"></th>
                  <th class="border border-gray-600 p-3 text-left text-sm font-semibold"></th>
                </tr>
              </thead>
              <tbody>
                <%= if Enum.empty?(@docket_data.courses) do %>
                <tr>
                  <td colspan="5" class="border border-gray-300 p-3 text-center text-sm text-black-600">
                    No courses available for this docket type.
                  </td>
                </tr>
                <% else %>
                  <%= for %{course: course} <- @docket_data.courses do %>
                  <tr>
                    <td class="border border-gray-600 p-3 text-sm"><%= course.code %></td>
                    <td class="border border-gray-600 p-3 text-sm"><%= course.title %></td>
                    <td class="border border-gray-600 p-3 text-sm"></td>
                    <td class="border border-gray-600 p-3 text-sm"></td>
                    <td class="border border-gray-600 p-3 text-sm"></td>
                  </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>

          <!-- Notes Section -->
          <div class="p-8">
            <h3 class="font-semibold mb-3">Note:</h3>
            <ol class="text-sm space-y-2 list-decimal list-inside">
              <li>All Students are expected to sign the Exam Attendance Register as evidence that one has sat for the Exam.</li>
              <li>The Exam docket is not the Exam Attendance Register.</li>
              <li>Students must only sign this document on the last day of their Exam and leave the form with the invigilator.</li>
              <li>This document is a proof that the student has registered for the Exam.</li>
              <li>All students must possess a CUZ ID card and Authorization from Finance.</li>
            </ol>
          </div>

          <!-- Signature Section -->
          <div class="p-8">
            <div class="grid grid-cols-2 gap-4">
              <!-- Finance -->
              <div class="space-y-2">
                <div class="h-8"></div>
                <p class="text-sm font-semibold">Signed: --------------------------------</p>
                <p class="text-sm font-semibold text-center">Finance </p>
                <p class="text-sm font-semibold">Date: --------------------------------</p>
              </div>

              <!-- Student -->
              <div class="space-y-2">
                <div class="h-8"></div>
                <p class="text-sm font-semibold">Signed: --------------------------------</p>
                <p class="text-sm font-semibold text-center">Student</p>
                <p class="text-sm font-semibold">Date: --------------------------------</p>
              </div>

              <!-- Dean -->
              <div class="space-y-2">
                <div class="h-5"></div>
                <p class="text-sm font-semibold">Signed: --------------------------------</p>
                <p class="text-sm font-semibold text-center">Dean of BIT</p>
                <p class="text-sm font-semibold">Date: --------------------------------</p>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="p-8 border-t border-gray-300 bg-gray-50 flex gap-4 justify-end print:hidden">
            <button
              phx-click="download_pdf"
              class="px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
            >
              Download PDF
            </button>
            <button
              onclick="window.print()"
              class="px-6 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition-colors"
            >
              Print
            </button>
            <a
              href="/Students/dockets"
              class="px-6 py-2 bg-gray-400 text-white rounded hover:bg-gray-500 transition-colors inline-block"
            >
              Back
            </a>
          </div>
        </div>
      </div>

      <script>
        window.addEventListener("phx:download_pdf", (event) => {
          const { filename, content } = event.detail;

          // Create a blob from the base64 content
          const byteCharacters = atob(content);
          const byteNumbers = new Array(byteCharacters.length);
          for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
          }
          const byteArray = new Uint8Array(byteNumbers);
          const blob = new Blob([byteArray], { type: 'application/pdf' });

          // Create download link and trigger download
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = filename;
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });
      </script>

    """

  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("download_pdf", _, socket) do
    current_user = socket.assigns.current_user
    docket_type = socket.assigns.docket_type

    case Dockets.generate_docket_html(current_user.id, docket_type, "/images/CUZ_Logo.png") do
      {:ok, docket_data} ->
        docket_name = Dockets.docket_type_name(docket_type)

        # Generate PDF from HTML
        case PdfGenerator.generate_binary(docket_data, filename: "#{docket_name}_#{current_user.first_name}_#{current_user.last_name}.pdf") do
          {:ok, pdf_binary} ->
            # Send the PDF as a download
            {:noreply,
             socket
             |> push_event("download_pdf", %{
               filename: "#{docket_name}_#{current_user.first_name}_#{current_user.last_name}.pdf",
               content: Base.encode64(pdf_binary)
             })}

          {:error, reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to generate PDF: #{inspect(reason)}")}
        end

      _error ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to generate docket data")}
    end
  end

  @impl true
  def handle_event("print", _, socket) do
    {:noreply, socket}
  end

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end
end
