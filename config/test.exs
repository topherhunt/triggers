use Mix.Config

config :logger, level: :warn

config :triggers, Triggers.Repo,
  url: H.env!("DATABASE_URL"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  # long timeout to allow debugging in tests
  ownership_timeout: 20 * 60 * 1000

config :triggers, TriggersWeb.Endpoint,
  http: [port: 4001], # must be 4001 for Chromedriver (I think)
  server: true # required by Hound

# By default we use Chromedriver in headless mode.
# Comment out the :browser key to default to headful mode for debugging tests.
config :hound, driver: "chrome_driver", browser: "chrome_headless"

config :rollbax, enabled: false

# Weaker password hashing so tests run faster
config :argon2_elixir, t_cost: 1, m_cost: 8
