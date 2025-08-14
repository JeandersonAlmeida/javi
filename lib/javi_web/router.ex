defmodule JaviWeb.Router do
  use JaviWeb, :router

  import JaviWeb.UserAuth
  import JaviWeb.StaffAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JaviWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_current_staff
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", JaviWeb do
    pipe_through :browser

    live "/", Landing.LandingLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", JaviWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:javi, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JaviWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", JaviWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{JaviWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/cadastrar", Account.RegistrationLive, :new
      live "/entrar", Account.LoginLive, :new
      live "/redefinir-senha", Account.ForgotPasswordLive, :new
      live "/redefinir-senha/:token", Account.ResetPasswordLive, :edit
    end

    post "/entrar", UserSessionController, :create
  end

  scope "/", JaviWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{JaviWeb.UserAuth, :ensure_authenticated}] do
      live "/inicio", Home.DashboardLive, :index
      live "/home", Home.DashboardLive, :index
      live "/listas", Home.ListLive, :index
      live "/lists", Home.ListLive, :index
      live "/listas/:id", Home.ListDetailLive, :show
      live "/lists/:id", Home.ListDetailLive, :show
      live "/titulos/:id", Home.TitleDetailLive, :show
      live "/titles/:id", Home.TitleDetailLive, :show
      live "/pesquisar", Home.SearchLive, :index
      live "/search", Home.SearchLive, :index
      # Section routes with descriptive names for better SEO
      live "/filmes-em-alta", Home.SectionTitlesLive, :show
      live "/series-populares", Home.SectionTitlesLive, :show
      live "/lancamentos-recentes", Home.SectionTitlesLive, :show
      live "/melhores-avaliados", Home.SectionTitlesLive, :show
      live "/genero/:genre_name/:genre_id", Home.SectionTitlesLive, :show
      live "/perfil", Home.ProfileLive, :index
      live "/users/settings", Home.UserSettingsLive, :edit
      live "/amigos", Home.FriendsLive, :index
      live "/configuracoes", Home.UserSettingsLive, :edit
      live "/configuracoes/confirmar-email/:token", Home.UserSettingsLive, :confirm_email
      live "/users/settings/confirm_email/:token", Home.UserSettingsLive, :confirm_email
      live "/onboarding", Onboarding.OnboardingLive, :index
    end
  end

  ## Staff (Ops) authentication routes
  scope "/ops", JaviWeb do
    pipe_through [:browser, :redirect_if_staff_is_authenticated]
    live "/login", Ops.StaffUserLoginLive, :new
    post "/login", StaffSessionController, :create
  end

  ## Staff (Ops) protected routes
  scope "/ops", JaviWeb do
    pipe_through [:browser, :require_authenticated_staff]

    live_session :require_authenticated_staff,
      on_mount: [{JaviWeb.StaffAuth, :ensure_staff_authenticated}] do
      live "/", Ops.DashboardLive, :index
    end

    delete "/logout", StaffSessionController, :delete
  end

  scope "/", JaviWeb do
    pipe_through [:browser]

    delete "/sair", UserSessionController, :delete
    get "/sair", UserSessionController, :logout
    delete "/users/log_out", UserSessionController, :delete
    get "/users/log_in", UserSessionController, :logout

    live_session :current_user,
      on_mount: [{JaviWeb.UserAuth, :mount_current_user}] do
      live "/confirmar/:token", Account.ConfirmationLive, :edit
      live "/confirmar", Account.ConfirmationInstructionsLive, :new
    end
  end

  # Public user profile by nickname - must be last to avoid conflicting with other routes
  scope "/", JaviWeb do
    pipe_through [:browser]

    live_session :public_profile,
      on_mount: [{JaviWeb.UserAuth, :mount_current_user}] do
      live "/:user_nickname", Public.UserProfileLive, :show
    end
  end
end
