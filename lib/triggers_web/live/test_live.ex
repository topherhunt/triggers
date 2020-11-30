# A simple test LiveView, mounted at the router.
# NOTE: I'm not in love with this router-mounting stuff.
# I might stick with controller-mounted liveviews.
defmodule TriggersWeb.TestLive do
  use TriggersWeb, :live_view

  def render(assigns) do
    ~L"""
      <h1>LiveView test</h1>
      Count: <%= @count %>
      <button phx-click="inc">Increment</button>
      <button phx-click="dec">Decrement</button>
    """
  end

  def mount(_params, assigns, socket) do
    IO.inspect(assigns, label: "assigns")

    socket
    |> assign(current_user: nil)
    |> assign(count: 0)
    |> ok()
  end

  def handle_event("inc", _value, socket) do
    socket
    |> assign(count: socket.assigns.count + 1)
    |> noreply()
  end

  def handle_event("dec", _value, socket) do
    socket
    |> assign(count: socket.assigns.count - 1)
    |> noreply()
  end

  #
  # Low-level helpers
  #

  defp ok(socket), do: {:ok, socket}
  defp noreply(socket), do: {:noreply, socket}
end
