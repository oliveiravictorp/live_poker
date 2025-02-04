defmodule LivePoker.Presence do
  use Phoenix.Presence,
    otp_app: :live_poker,
    pubsub_server: LivePoker.PubSub
end
