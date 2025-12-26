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
      live "/users/register", Auth.LoginLive.UserRegistrationLive, :new
      live "/users/login", Auth.LoginLive.Index, :new
      live "/users/reset_password", Auth.UserForgotPasswordLive, :new
      live "/users/reset_password/:token", Auth.LoginLive.UserResetPasswordLive, :edit
    end

    post "/users/login", UserSessionController, :create
  end

  # ======================= ADMIN ROUTES =============================
  scope "/Admin", RegisterWeb do
    pipe_through [:browser, :admin_only, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RegisterWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", Admin.Dashboard.Index, :index
      live "/users/settings", Auth.SettingsLive.Index, :edit
      live "/users/settings/confirm_email/:token", Auth.SettingsLive.Index, :confirm_email

      # ==================== COURSE MANAGEMENT =========================
      live "/courses", Admin.CoursesLive.Index, :index
      live "/courses/new", Admin.CoursesLive.Index, :new
      live "/courses/:id/edit", Admin.CoursesLive.Index, :edit

      # ==================== STUDENT MANAGEMENT =========================
      live "/students", Admin.StudentsLive.Index, :index
      live "/students/new", Admin.StudentsLive.Index, :new
      live "/students/:id", Admin.StudentsLive.Show, :show
      live "/students/:id/edit", Admin.StudentsLive.Index, :edit

      # ==================== LECTURER & ADMIN/STAFF MANAGEMENT =========
      live "/lecturers", Admin.LecturersLive.Index, :index
      live "/lecturers/:id/courses", Admin.LecturerLive.CoursesLive.Index, :edit, as: :admin_lecturer_courses
      live "/admins-staff", Admin.AdminsStaffLive.Index, :index

      # ==================== PROGRAM MANAGEMENT =========================
      live "/programs", Admin.ProgramLive.Index, :index
      live "/programs/new", Admin.ProgramLive.Index, :new
      live "/programs/:id", Admin.ProgramLive.Index, :show
      live "/programs/:id/edit", Admin.ProgramLive.Index, :edit
      live "/programs/:id/manage_courses", Admin.ProgramLive.Index, :manage_courses

      # ==================== USERS MGT =================================
      live "/users", Admin.UserMgtLive.Index, :index

      # ==================== QR CODE MANAGEMENT =========================
      live "/qr-codes", Admin.QrCodeLive.Index, :index
      live "/qr-codes/new", Admin.QrCodeLive.Index, :new
      live "/qr-codes/:id/edit", Admin.QrCodeLive.Index, :edit
      live "/qr-codes/:id/show", Admin.QrCodeLive.ShowComponent, :show

      # ==================== ADMIN ATTENDANCE =========================
      live "/attendance/record", Admin.AttendanceLive.AttendanceRecords.Record, :record
      live "/attendance/view", Admin.AttendanceLive.AttendanceView.Index, :index

      # ==================== PROGRAM MANAGEMENT =========================
      live "/programs", Admin.ProgramLive.Index, :index
      live "/programs/new", Admin.ProgramLive.Index, :new
      live "/programs/:id/edit", Admin.ProgramLive.Index, :edit
      live "/programs/:id/manage_courses", Admin.ProgramLive.Index, :manage_courses

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
      live "/users/settings", Auth.SettingsLive.Index, :edit

      # ===================== LECTURER ATTENDANCE =====================
      live "/attendance/view", Lecturer.AttendanceLive.Index, :index

      # ===================== LECTURER QR CODES =======================
      live "/qr-codes", Lecturer.QrCodesLive.Index, :index

      live "/otp-management", Lecturer.OTPLive.Index, :index
      live "/otp-management/new", Lecturer.OTPLive.Index, :new
      live "/otp-management/:id", Lecturer.OTPLive.Index, :show

    end
  end

  # =========================== STUDENT ROUTES =========================
  scope "/Students", RegisterWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :student_authenticated,
      on_mount: [{RegisterWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", Students.Dashboard.Index, :index
      live "/users/settings", Auth.SettingsLive.Index, :edit
      live "/enter-register-otp", Students.EnterRegisterOtpLive, :new


      live "/otp-management", Students.OtpLive.Index, :index
      live "/otp-management/:id", Students.OtpLive.Index, :show
      live "/otp-management/:id/verify", Students.OtpLive.Index, :verify


      live "/qr-codes", Students.QrCodesLive.Index, :index
      live "/qr-codes/:id", Students.QrCodesLive.Index, :show
      live "/qr-codes/:id/verify", Students.QrCodesLive.Index, :verify

      # ===================== STUDENT COURSES =========================
      live "/courses", Students.CoursesLive.Index, :index

      # ===================== STUDENT ATTENDANCE ======================
      live "/attendance", Students.AttendanceLive.Index, :index

      # ===================== STUDENT QR SCANNER =======================
      live "/scan", Students.ScanLive.Index, :index

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
