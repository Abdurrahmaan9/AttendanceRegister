defmodule RegisterWeb.Admin.QrCodeLive.Index do
  use RegisterWeb, :live_view
  import RegisterWeb.Utils

  alias Register.QrCodes, as: QR
  alias Register.QrCodes.QrCode

  @impl true
  def mount(_params, session, socket) do
    current_user = get_session_user(session)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:page_title, "Generate QR Code")
      |> assign(:sidebar_open, false)
      |> assign(:changeset, QrCode.changeset(%QrCode{}, %{}))
      |> assign(:qr_codes, [])
      |> assign(:qr_svg, nil)
      |> assign(:created_qr, nil)
      |> assign(:editing_qr, nil)
      |> assign(:loading, !connected?(socket))

    if connected?(socket) and current_user do
      {:ok, load_qr_codes(socket)}
    else
      {:ok, socket}
    end
  end

  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_id(id), do: id

  defp get_session_user(session) do
    case session["user_token"] do
      nil -> nil
      token -> Register.Accounts.get_user_by_session_token(token)
    end
  end

  defp load_qr_codes(%{assigns: %{current_user: %{id: user_id}}} = socket) do
    codes = QR.list_qr_codes() |> Enum.filter(&(&1.created_by_id == user_id))
    assign(socket, :qr_codes, codes)
  end

  defp load_qr_codes(socket), do: socket

  @impl true
  def handle_event("validate", %{"qr_code" => params}, socket) do
    changeset =
      %QrCode{}
      |> QrCode.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("new_qr", _params, socket) do
    {:noreply,
      socket
      |> assign(:changeset, QrCode.changeset(%QrCode{}, %{}))
      |> assign(:editing_qr, nil)
    }
  end

  @impl true
  def handle_event("save", %{"qr_code" => params}, %{assigns: %{current_user: user, editing_qr: nil}} = socket) do
    params =
      params
      |> Map.put("created_by_id", user.id)
      |> Map.put("qr_data", build_qr_data(params, user))
      |> put_default_active()

    case QR.create_qr_code(params) do
      {:ok, qr} ->
        {:noreply,
          socket
          |> put_flash(:info, "QR code generated.")
          |> assign(:created_qr, qr)
          |> assign(:qr_svg, generate_qr_svg(qr.qr_data))
          |> assign(:changeset, QrCode.changeset(%QrCode{}, %{}))
          |> assign(:editing_qr, nil)
          |> load_qr_codes()
          |> push_navigate(to: ~p"/Admin/qr-codes")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"qr_code" => params}, %{assigns: %{editing_qr: %QrCode{} = qr}} = socket) do
    params =
      params
      |> Map.delete("qr_data")
      |> put_default_active()

    case QR.update_qr_code(qr, params) do
      {:ok, qr} ->
        {:noreply,
          socket
          |> put_flash(:info, "QR code updated.")
          |> assign(:created_qr, qr)
          |> assign(:qr_svg, generate_qr_svg(qr.qr_data))
          |> assign(:changeset, QrCode.changeset(%QrCode{}, %{}))
          |> assign(:editing_qr, nil)
          |> load_qr_codes()
          |> push_navigate(to: ~p"/Admin/qr-codes")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("view_qr", %{"id" => id}, socket) do
    qr = QR.get_qr_code!(parse_id(id))
    {:noreply,
      socket
      |> assign(:created_qr, qr)
      |> assign(:qr_svg, generate_qr_svg(qr.qr_data))
    }
  end

  @impl true
  def handle_event("edit_qr", %{"id" => id}, socket) do
    qr = QR.get_qr_code!(parse_id(id))
    {:noreply,
      socket
      |> assign(:changeset, QrCode.changeset(qr, %{}))
      |> assign(:editing_qr, qr)
    }
  end

  @impl true
  def handle_event("delete_qr", %{"id" => id}, socket) do
    qr = QR.get_qr_code!(parse_id(id))
    {:ok, _} = QR.delete_qr_code(qr)

    socket =
      case socket.assigns.created_qr do
        %QrCode{id: id} when id == qr.id -> assign(socket, created_qr: nil, qr_svg: nil)
        _ -> socket
      end

    {:noreply, load_qr_codes(socket)}
  end

  defp put_default_active(params) do
    case Map.has_key?(params, "is_active") do
      true -> params
      false -> Map.put(params, "is_active", "true")
    end
  end

  defp build_qr_data(params, user) do
    data = %{
      id: Ecto.UUID.generate(),
      type: "attendance",
      lecturer_id: user.id,
      class_name: Map.get(params, "class_name"),
      program_name: Map.get(params, "program_name"),
      name: Map.get(params, "name"),
      t: System.system_time(:second)
    }

    Jason.encode!(data)
  end

  defp generate_qr_svg(data) do
    qr = EQRCode.encode(to_string(data))
    EQRCode.svg(qr, width: 300)
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
end
