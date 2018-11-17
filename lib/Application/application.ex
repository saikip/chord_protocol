defmodule Chord_Protocol.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Chord_Protocol.Worker.start_link(arg)
      # {Chord_Protocol.Worker, arg},
    ]
    opts = [strategy: :one_for_one, name: Chord_Protocol.Supervisor]
    Supervisor.start_link(children, opts)
  end
end