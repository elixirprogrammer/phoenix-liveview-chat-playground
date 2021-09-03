defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)

    if connected?(socket) do
      ChatWeb.Endpoint.subscribe(topic)
      ChatWeb.Presence.track(self(), topic, username, %{})
    end

    {:ok,
     socket
     |> assign(room_id: room_id)
     |> assign(username: username)
     |> assign(topic: topic)
     |> assign(message: "")
     |> assign(user_list: [])
     |> assign(messages: []), temporary_assigns: [messages: []]}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)

    {:noreply,
     socket
     |> assign(message: "")}
  end

  def handle_event("form_updated", %{"chat" => %{"message" => message}}, socket) do
    {:noreply,
     socket
     |> assign(message: message)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply,
     socket
     |> assign(messages: [message])}
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} joined"}
      end)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} left"}
      end)

    user_list =
      ChatWeb.Presence.list(socket.assigns.topic)
      |> Map.keys()

    {:noreply,
     socket
     |> assign(messages: join_messages ++ leave_messages)
     |> assign(user_list: user_list)}
  end

  defp display_message(%{type: :system, uuid: uuid, content: content}) do
    ~E"""
    <p id="<%= uuid %>"><em><%= content %></em></p>
    """
  end

  defp display_message(%{uuid: uuid, content: content, username: username}) do
    ~E"""
    <p id="<%= uuid %>">
      <strong><%= username %></strong>: <%= content %>
    </p>
    """
  end
end
