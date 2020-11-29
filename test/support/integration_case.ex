defmodule TriggersWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Hound.Helpers # See https://github.com/HashNuke/hound for usage info
      import Plug.Conn
      import Phoenix.ConnTest
      import Triggers.EmailHelpers
      import TriggersWeb.IntegrationHelpers
      alias TriggersWeb.Router.Helpers, as: Routes
      alias Triggers.Factory

      @endpoint TriggersWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Triggers.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Triggers.Repo, {:shared, self()})
    end

    # Triggers.DataHelpers.empty_database()
    ensure_driver_running()
    System.put_env("SUPERADMIN_EMAILS", "superadmin@example.com")
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def ensure_driver_running do
    {processes, _code} = System.cmd("ps", [])

    unless processes =~ "chromedriver" do
      raise "Integration tests require ChromeDriver. Run `chromedriver` first."
    end
  end
end
