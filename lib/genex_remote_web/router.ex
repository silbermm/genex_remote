defmodule GenexRemoteWeb.Router do
  use GenexRemoteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GenexRemoteWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug GenexRemoteWeb.Plugs.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug GenexRemoteWeb.Plugs.ApiAuthPlug
  end

  live_session :profile, on_mount: GenexRemoteWeb.Plugs.AuthHook do
    scope "/profile", GenexRemoteWeb do
      pipe_through :browser

      live "/", ProfileLive.Index, :index
      live "/logs", ProfileLive.Index, :logs
    end
  end

  live_session :auth, on_mount: {GenexRemoteWeb.Plugs.AuthHook, :maybe_load} do
    scope "/", GenexRemoteWeb do
      pipe_through :browser

      live "/register", AuthLive.Register, :register
      live "/register/validate", AuthLive.Register, :validate
      live "/register/success", AuthLive.Register, :success
      live "/login", AuthLive.Login, :login

      get "/login/:token/email/:email", SessionController, :create_from_token
      get "/logout", SessionController, :logout

      live "/", HomeLive.Index, :index
    end
  end

  scope "/api", GenexRemoteWeb do
    pipe_through :api

    put "/login/:email", SessionController, :api_request_challenge
    post "/login/:email", SessionController, :api_submit_challenge_response

    scope "/" do
      pipe_through :api_authenticated

      get "/passwords", PasswordsController, :list
      post "/passwords", PasswordsController, :save
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GenexRemoteWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
