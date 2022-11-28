defmodule GenexRemote.PubSub do
  @moduledoc """
  A central module for defining all topic names
  """

  alias Phoenix.PubSub

  def account_logs(account_id), do: "account_logs:#{account_id}"

  def subscribe(topic), do: PubSub.subscribe(__MODULE__, topic)
  def broadcast(topic, payload), do: PubSub.broadcast(__MODULE__, topic, payload)
end
