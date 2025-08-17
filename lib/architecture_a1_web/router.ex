defmodule ArchitectureA1Web.Router do
  use ArchitectureA1Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ArchitectureA1Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ArchitectureA1Web do
    pipe_through :browser

    get "/", PageController, :index

    get "/books/top_selling", BookController, :top_selling
    resources "/books", BookController
    post "/seed", SeedController, :seed_data
    get  "/books/:book_id/reviews",            ReviewController, :index
    post "/books/:book_id/reviews",            ReviewController, :create
    post "/books/:book_id/reviews/:id/upvote", ReviewController, :upvote
    get "/books/:book_id/reviews/:id/edit", ReviewController, :edit
    delete "/books/:book_id/reviews/:id",      ReviewController, :delete
    put "/books/:book_id/reviews/:id", ReviewController, :update
    get "/reviews", ReviewController, :all_reviews
    get "/authors/stats", AuthorController, :stats
    resources "/authors", AuthorController
    resources "/sales", SaleController
  end

  # Other scopes may use custom stacks.
  # scope "/api", ArchitectureA1Web do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:architecture_a1, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ArchitectureA1Web.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
