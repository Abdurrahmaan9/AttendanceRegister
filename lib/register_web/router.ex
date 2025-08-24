defmodule RegisterWeb.Router do
  use RegisterWeb, :router

  import RegisterWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RegisterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin_only do
    plug RegisterWeb.Plugs.RequireRole, ["admin"]
  end

  pipeline :lecturer_only do
    plug RegisterWeb.Plugs.RequireRole, ["lecturer"]
  end


  scope "/", RegisterWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
  end

  # Other scopes may use custom stacks.
  # scope "/api", RegisterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:register, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RegisterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", RegisterWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{RegisterWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", Auth.UserRegistrationLive, :new
      live "/users/login", Auth.LoginLive, :new
      live "/users/reset_password", Auth.UserForgotPasswordLive, :new
      live "/users/reset_password/:token", Auth.UserResetPasswordLive, :edit
    end

    post "/users/login", UserSessionController, :create
  end

  # ======================= ADMIN ROUTES =============================
  scope "/Admin", RegisterWeb do
    pipe_through [:browser, :admin_only, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RegisterWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", Admin.Dashboard.Index, :index
      live "/users/settings", Auth.UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", Auth.UserSettingsLive, :confirm_email

      # ==================== COURSE MANAGEMENT =========================
      live "/courses", Admin.CoursesLive.Index, :index
      live "/courses/new", Admin.CoursesLive.Index, :new
      live "/courses/:id/edit", Admin.CoursesLive.Index, :edit

      # ==================== STUDENT MANAGEMENT =========================
      live "/students", Admin.StudentsLive.Index, :index
      live "/students/new", Admin.StudentsLive.Index, :new
      live "/students/:id/edit", Admin.StudentsLive.Index, :edit

      # ==================== USERS MGT =================================
      live "/users", Admin.UsersLive.Index, :index

      # ==================== QR CODE MANAGEMENT =========================
      live "/qr-codes", Admin.QrCodeLive.Index, :index
      live "/qr-codes/new", Admin.QrCodeLive.Index, :new
      live "/qr-codes/:id/edit", Admin.QrCodeLive.Index, :edit
      live "/qr-codes/:id/show", Admin.QrCodeLive.ShowComponent, :show

      # ==================== OTP MANAGEMENT =========================
      live "/otp-management", Admin.OTPManagementLive.Index, :index
      live "/otp-management/new", Admin.OTPManagementLive.Index, :new
      live "/otp-management/:id/edit", Admin.OTPManagementLive.Index, :edit
    end
  end

    # ========================= LECTURER ROUTES =========================
  scope "/Lecturer", RegisterWeb do
    pipe_through [:browser, :lecturer_only, :require_authenticated_user]

    live_session :lecturer_authenticated,
      on_mount: [{RegisterWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", Lecturer.Dashboard.Index, :index
    end
  end

  # =========================== STUDENT ROUTES =========================
  scope "/Students", RegisterWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :student_authenticated,
      on_mount: [{RegisterWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", Students.Dashboard.Index, :index
      live "/enter-register-otp", Students.EnterRegisterOtpLive, :new
    end
  end

  scope "/", RegisterWeb do
    pipe_through [:browser]

    get "/users/log_out", UserSessionController, :delete
    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{RegisterWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", Auth.UserConfirmationLive, :edit
      live "/users/confirm", Auth.UserConfirmationInstructionsLive, :new
    end
  end
end
