defmodule ChatWeb.PageLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("random-room", _params, socket) do
    random_slug = "/" <> MnemonicSlugs.generate_slug(4)
    {:noreply,
      socket
      |> push_redirect(to: random_slug)}
  end
end
