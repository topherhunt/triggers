defmodule Triggers.Emails do
  use Bamboo.Phoenix, view: TriggersWeb.EmailsView
  import Bamboo.Email
  import TriggersWeb.Gettext
  alias TriggersWeb.Router.Helpers, as: Routes
  alias Triggers.Data
  alias Triggers.Data.User
  alias Triggers.Factory
  require Logger

  @endpoint TriggersWeb.Endpoint

  def confirm_address(%User{} = user, email) do
    token = Data.create_token!({:confirm_email, user.id, email})
    url = Routes.auth_url(@endpoint, :confirm_email, token: token)
    if Mix.env == :dev, do: Logger.info "Email confirmation link sent to #{email}: #{url}"

    standard_email()
    |> to(email)
    |> subject("Triggers: #{gettext "Please confirm your address"}")
    |> render("confirm_address.html", url: url)
  end

  def reset_password(%User{} = user) do
    token = Data.create_token!({:reset_password, user.id})
    url = Routes.auth_url(@endpoint, :reset_password, token: token)
    if Mix.env == :dev, do: Logger.info "PW reset link sent to #{user.email}: #{url}"

    standard_email()
    |> to(user.email)
    |> subject("Triggers: #{gettext "Use this link to reset your password"}")
    |> render("reset_password.html", url: url)
  end

  def nag(user, triggers) do
    preview = triggers |> Enum.map(& &1.title) |> Enum.join(", ") |> String.slice(0..100)

    standard_email()
    |> to(user.email)
    |> subject("#{length(triggers)} due triggers: #{preview} - #{Factory.random_uuid()}")
    |> render("nag.html", triggers: triggers)
  end

  #
  # Internal
  #

  defp standard_email do
    new_email()
    |> from({"Triggers", "noreply@triggers.topherhunt.com"})
    |> put_html_layout({TriggersWeb.LayoutView, "email.html"})
  end
end
