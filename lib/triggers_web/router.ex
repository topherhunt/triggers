defmodule TriggersWeb.Router do
  use TriggersWeb, :router
  use Plug.ErrorHandler # for Rollbax
  import TriggersWeb.AuthPlugs, only: [load_current_user: 2]
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router
  alias Triggers.Helpers, as: H

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_current_user
    plug :put_root_layout, {TriggersWeb.LayoutView, :root} # for LiveView
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :dashboard_auth do
    plug :basic_auth, username: "admin", password: H.env!("DASHBOARD_PASSWORD")
  end

  # In dev, preview all "sent" emails at localhost:4000/sent_emails
  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  scope "/" do
    pipe_through [:browser, :dashboard_auth]
    live_dashboard "/dashboard", metrics: Triggers.Telemetry
  end

  scope "/", TriggersWeb do
    pipe_through :browser

    get "/", PageController, :index

    live "/test_live", TestLive

    get "/auth/signup", AuthController, :signup
    post "/auth/signup", AuthController, :signup_submit
    get "/auth/login", AuthController, :login
    post "/auth/login", AuthController, :login_submit
    get "/auth/logout", AuthController, :logout
    get "/auth/request_email_confirm", AuthController, :request_email_confirm
    post "/auth/request_email_confirm", AuthController, :request_email_confirm_submit
    get "/auth/confirm_email", AuthController, :confirm_email
    get "/auth/request_password_reset", AuthController, :request_password_reset
    post "/auth/request_password_reset", AuthController, :request_password_reset_submit
    get "/auth/reset_password", AuthController, :reset_password
    post "/auth/reset_password", AuthController, :reset_password_submit

    get "/account/edit", UserController, :edit
    patch "/account/update", UserController, :update
    patch "/account/update_email", UserController, :update_email

    get "/triggers/upcoming", TriggerController, :upcoming
    get "/triggers/history", TriggerController, :history
    get "/triggers/:instance_id/resolve", TriggersController, :resolve
    resources "/triggers", TriggerController, except: [:index]
  end

  # Other scopes may use custom stacks.
  # scope "/api", TriggersWeb do
  #   pipe_through :api
  # end

  defp handle_errors(conn, data), do: TriggersWeb.ErrorPlugs.handle_errors(conn, data)
end
