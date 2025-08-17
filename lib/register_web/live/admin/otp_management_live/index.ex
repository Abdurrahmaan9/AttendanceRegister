defmodule RegisterWeb.Admin.OTPManagementLive.Index do
  use RegisterWeb, :live_view
  
  alias Phoenix.LiveView.JS
  alias Register.Otps
  alias Register.Otps.Otp
  alias Register.Repo
  
  import RegisterWeb.Admin.OTPManagementLive.Helpers
  import RegisterWeb.CoreComponents

  @impl true
  def mount(_params, _session, socket) do
    require Logger
    Logger.debug("Mounting OTP Management LiveView")
    
    if connected?(socket) do
      Logger.debug("Socket is connected, loading OTPs...")
      
      try do
        # Try to list OTPs directly
        otps = Otps.list_otps()
        Logger.debug("Loaded #{length(otps)} OTPs")
        
        # Verify the first OTP's structure if it exists
        if Enum.any?(otps) do
          otp = List.first(otps)
          Logger.debug("First OTP: #{inspect(otp, limit: :infinity, pretty: true)}")
          Logger.debug("OTP created_by: #{inspect(otp.created_by, limit: :infinity, pretty: true)}")
        end
        
        {:ok, assign(socket, otps: otps, id: "otp-management")}
      rescue
        e ->
          Logger.error("Error loading OTPs: #{inspect(e)}")
          {:ok, assign(socket, otps: [], id: "otp-management", error: "Error loading OTPs")}
      end
    else
      Logger.debug("Socket not connected, using empty OTP list")
      {:ok, assign(socket, otps: [], id: "otp-management")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage OTPs")
    |> assign(:otp, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New OTP")
    |> assign(:otp, %Otp{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    otp = Otps.get_otp!(id)
    
    socket
    |> assign(:page_title, "Edit OTP")
    |> assign(:otp, otp)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    otp = Otps.get_otp!(id)
    {:ok, _} = Otps.delete_otp(otp)
    
    otps = Otps.list_otps()
    
    {:noreply, 
      socket
      |> put_flash(:info, "OTP deleted successfully")
      |> assign(:otps, otps)
    }
  end

  @impl true
  def handle_info({:otp_created, _otp}, socket) do
    otps = Otps.list_otps()
    {:noreply, assign(socket, :otps, otps)}
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    otp = Otps.get_otp!(id)
    {:ok, updated_otp} = Otps.update_otp(otp, %{is_active: !otp.is_active})
    
    otps = Otps.list_otps()
    
    status = if updated_otp.is_active, do: "activated", else: "deactivated"
    
    {:noreply, 
      socket
      |> put_flash(:info, "OTP #{status} successfully")
      |> assign(:otps, otps)
    }
  end

  @impl true
  def handle_event("close-dropdown", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-dropdown", %{"id" => id}, socket) do
    {:noreply, socket}
  end
end
