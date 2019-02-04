defmodule SwiftApi.IdentityTokenWorker do
  @moduledoc false
  
  use Agent

  def start_link(_state, _opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def update_token(token) do
    Agent.update(__MODULE__, & Map.merge(&1, %{token: token}))
  end

  def update_identity_info(info) do
    Agent.update(__MODULE__, & Map.merge(&1, %{identity: info}))
  end

  def get_token do
    data = Agent.get(__MODULE__, & &1)
    data[:token]
  end

  def get_swift_url(time_now \\ Timex.now) do
    case check_time_validity(time_now) do
      true ->
        data = Agent.get(__MODULE__, & &1)
        catalog = data[:identity]["token"]["catalog"] || []
        catalog
        |> Enum.find(& &1["name"] == "swift")
        |> Map.values
        |> List.flatten
        |> Enum.filter(&is_map/1)
        |> Enum.filter(& &1["interface"] == "public")
        |> Enum.at(0)
        |> Map.fetch!("url")
      false ->
        clear()
        nil
    end
  end

  def get_identity_info do
    :ok
  end

  def check_time_validity(time_now \\ Timex.now) do
    data = Agent.get(__MODULE__, & &1)
    expires_at_str = data[:identity]["token"]["expires_at"] || ""
    case Timex.parse(expires_at_str, "{ISO:Extended}") do
      {:ok, expires_at} -> !Timex.before?(expires_at, time_now)
      {:error, _} -> false
    end
  end

  defp clear do
    Agent.update(__MODULE__, fn _current_state -> %{} end)
  end
end