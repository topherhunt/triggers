defmodule TriggersWeb.ConnHelpers do
  use ExUnit.CaseTemplate
  # import Plug.Conn
  import Phoenix.ConnTest
  alias Triggers.Factory
  alias TriggersWeb.Router.Helpers, as: Routes

  @endpoint TriggersWeb.Endpoint

  def login(conn, user) do
    # Plug.Conn.assign(conn, :current_user, user)
    params = %{"user" => %{"email" => user.email, "password" => "password"}}
    conn = post(conn, Routes.auth_path(conn, :login_submit), params)
    assert flash_messages(conn) == "Welcome back!"
    conn
  end

  def login_as_new_user(conn, user_params \\ []) do
    user = Factory.insert_user(user_params)
    conn = login(conn, user)
    {conn, user}
  end

  def assert_logged_in(conn, user) do
    conn = get(conn, Routes.page_path(conn, :index))
    assert conn.resp_body =~ "Log out"
    assert conn.resp_body =~ String.downcase(user.email)
    refute conn.resp_body =~ "Log in"
  end

  def assert_logged_out(conn) do
    conn = get(conn, Routes.page_path(conn, :index))
    assert conn.resp_body =~ "Log in"
    refute conn.resp_body =~ "Log out"
  end

  # Content can be plain text, HTML, or a regex.
  def assert_content(conn, content) do
    unless cleaned_body(conn) =~ content do
      filepath = write_response_body_to_file(conn.resp_body)
      raise "Expected the response html to include #{inspect(content)}, but it didn't. \nView the full response at: #{filepath}"
    end
  end

  def refute_content(conn, content) do
    if cleaned_body(conn) =~ content do
      filepath = write_response_body_to_file(conn.resp_body)
      raise "Expected the response html to NOT include #{inspect(content)}, but it did. \nView the full response at: #{filepath}"
    end
  end

  defp cleaned_body(conn) do
    conn.resp_body
    |> String.replace(~r/\s\s+/, " ")
    |> String.replace("&#39;", "'")
  end

  def assert_selector(conn, selector, opts \\ []) do
    {:ok, doc} = Floki.parse_document(conn.resp_body)
    matches = Floki.find(doc, selector)

    # Filter matches to those that match the :html pattern (if provided)
    matches =
      if opts[:html] do
        Enum.filter(matches, & Floki.raw_html(&1) =~ opts[:html])
      else
        matches
      end

    if opts[:count] do
      unless length(matches) == opts[:count] do
        filepath = write_response_body_to_file(conn.resp_body)
        raise "Expected to find selector '#{selector}' #{opts[:count]} times, but found it #{length(matches)} times. \nView the full html at: #{filepath}"
      end
    else
      unless length(matches) >= 1 do
        filepath = write_response_body_to_file(conn.resp_body)
        raise "Expected to find selector '#{selector}' one or more times, but found it 0 times. \nView the full html at: #{filepath}"
      end
    end
  end

  def refute_selector(conn, selector) do
    assert_selector(conn, selector, count: 0)
  end

  def write_response_body_to_file(source_html) do
    System.cmd("mkdir", ["-p", "./tmp/test_failures"])
    filename = "#{Date.utc_today}_#{Nanoid.generate(6)}.html"
    filepath = "./tmp/test_failures/#{filename}"
    File.write!(filepath, source_html)
    filepath
  end

  def flash_messages(conn) do
    conn.private.phoenix_flash |> Map.values() |> Enum.join(" ")
  end
end
