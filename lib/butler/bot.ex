defmodule Butler.Bot do
  use GenServer

  def start_link(adapter, events, plugins, opts \\ []) do
    GenServer.start_link(__MODULE__, {adapter, events, plugins}, name: :bot)
  end

  def respond(msg) do
    GenServer.call(:bot, {:respond, msg})
  end

  # Server callbacks

  def init({adapter, events, plugins}) do
    Enum.each(plugins, fn({handler, state}) ->
      GenEvent.add_handler(events, handler, state)
    end)

    {:ok, %{adapter: adapter, plugins: plugins, events: events}}
  end

  def handle_call({:respond, msg}, _from, state) do
    GenEvent.notify(state.events, {:message, msg, "", ""})
    {:reply, msg, state}
  end
end
