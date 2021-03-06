defmodule Butler.Plugin do
  @doc false
  defmacro __using__(_opts) do
    quote do
      use GenEvent

      @bot_name Application.get_env(:bot, :name)

      @before_compile Butler.Plugin


      def handle_event({:message, text, channel, slack}, state) do
        if bot_mentioned?(text) do
          parse_message(text) |> respond(state) |> handle_response(channel, slack)
        else
          hear(text, state) |> handle_response(channel, slack)
        end
      end

      defp handle_response({:noreply, state}, _channel, _slack), do: {:ok, state}

      defp handle_response({:reply, response, state}, channel, slack) do
        {:ok, msg} = response_message(response)
        send_message(msg, channel, slack.socket)
        {:ok, state}
      end

      def response_message(msg) when is_binary(msg) do
        response_message({:text, msg})
      end
      def response_message({:code, msg}),  do: {:ok, "```#{msg}```"}
      def response_message({:text, msg}),  do: {:ok, "#{msg}"}
      def response_message({:quote, msg}), do: {:ok, ">#{msg}"}
      def response_message(response) do
        require Logger
        
        Logger.error "Unknown response type"
        {:error, response}
      end

      def bot_mentioned?(text) do
        name = @bot_name |> String.downcase
        [first | _] = String.split(text)
        first |> String.downcase |> String.contains?(name)
      end

      def parse_message(text) do
        [_ | msg] = String.split(text)
        Enum.join(msg, " ")
      end

      def send_message(text, channel, socket, client \\ :websocket_client) do
        msg = Poison.encode!(%{ type: "message", text: text, channel: channel })
        client.send({:text, msg}, socket)
      end
    end
  end

  defmacro __before_compile__(env) do
    quote do
      def hear(_msg, state), do: {:noreply, state}
      def respond(_msg, state), do: {:noreply, state}
      defoverridable [hear: 2, respond: 2]
    end
  end
end
