defmodule SwiftApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: SwiftApi.Worker.start_link(arg)
       # {SwiftApi.Worker, []},
       {SwiftApi.IdentityTokenWorker, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SwiftApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
