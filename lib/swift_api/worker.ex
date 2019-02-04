defmodule SwiftApi.Worker do
  @moduledoc false
#  use GenServer
  @name SwiftApiWorker

  # client api
  # client = %SwiftApi.Client{}; SwiftApi.Worker.identity(client); SwiftApi.Worker.container_list(client, "")
  def container_list(client) do
    container_list(client, client.container)
  end

  def container_list(client, container \\ "") do
    url = "/#{container}"
    swift_get(client, url)
  end

  def container_create(client, container) do
    url = "/#{container}"
    swift_put(client, "", url)
  end

  def object_create(client, path, content) do
    swift_put(client, content, "/#{path}")
  end

  def identity(client) do
    hash = %{
      "auth": %{
        "identity": %{
          "methods": ["password"],
          "password": %{
            "user": %{
              "name": client.user_name,
              "password": client.password,
              "domain": %{
                "id": client.domain_id
              }
            }
          }
        },
        "scope": %{
          "project": %{
            "id": client.project_id
          }
        }
      }
    }

    identify_url = "#{client.url}/v3/auth/tokens"

    opts = case client.ca_certificate_path do
      nil -> []
      path -> [{:ssl_options, [{:cacertfile, path}]}]
    end

    headers = ["Content-Type": "application/json"]

    case HTTPoison.post identify_url, Poison.encode!(hash), headers, hackney: opts do
      {:ok, %HTTPoison.Response{body: body, headers: headers}} ->
        {"X-Subject-Token", token} = List.keyfind(headers, "X-Subject-Token", 0)
        SwiftApi.IdentityTokenWorker.update_token token
        SwiftApi.IdentityTokenWorker.update_identity_info Poison.decode!(body)
      error -> IO.inspect error
    end
  end

  def swift_get(client, url, 3) do
    {:error, "Can't authorize"}
  end

  def swift_get(client, url, identity_count \\ 0) do
    swift_url = SwiftApi.IdentityTokenWorker.get_swift_url()
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        identity(client)
        swift_get(client, url, identity_count + 1)
      swift_url ->
        _get(client, swift_url, url)
    end
  end

  def swift_put(client, content, url, 3) do
    {:error, "Can't authorize"}
  end

  def swift_put(client, content, url, identity_count \\ 0) do
    swift_url = SwiftApi.IdentityTokenWorker.get_swift_url()
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        identity(client)
        swift_put(client, content, url, identity_count + 1)
      swift_url ->
        _put(client, content, swift_url, url)
    end
  end

  def _put(client, content, swift_url, path, 3) do
    {:error, "Can't authorize"}
  end

  def _put(client, content, swift_url, path, identity_count \\ 0) do
    token = SwiftApi.IdentityTokenWorker.get_token
    final_url = "#{swift_url}#{path}"
    headers = ["X-Auth-Token": "#{token}"]
    http_params = ["format": "json"]
    options = [params: http_params]
    case HTTPoison.put(final_url, content, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        identity(client)
        _put(client, content, swift_url, path, identity_count + 1)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:ok, %HTTPoison.Response{body: "", status_code: 201}} -> {:ok, ""}
      {:ok, %HTTPoison.Response{status_code: 404}}
      {:ok, response} -> case Poison.decode(response.body) do
                           {:ok, map} -> {:ok, map}
                           {:error, msg} ->
                              IO.inspect(response)
                              {:error, response.body}
                           {:error, :invalid, descr} ->
                             IO.inspect(response)
                             {:error, response.body}
                         end
      {:error, error} ->
        IO.inspect(error)
        {:error, error}
    end
  end

  def _get(client, swift_url, path, 3) do
    {:error, "Can't authorize"}
  end

  def _get(client, swift_url, path, identity_count \\ 0) do
    token = SwiftApi.IdentityTokenWorker.get_token
    final_url = "#{swift_url}#{path}"
    headers = ["X-Auth-Token": "#{token}"]
    http_params = ["format": "json"]
    options = [params: http_params]
    case HTTPoison.get(final_url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        identity(client)
        _get(client, swift_url, path, identity_count + 1)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code == 200 or status_code == 202 ->
        case Poison.decode(body) do
          {:ok, map} -> {:ok, map}
          {:error, descr} -> {:ok, body}
          {:error, :invalid, descr}  -> {:ok, body}
        end
      {:error, error} ->
        IO.inspect(error)
        {:error, error}
    end
  end

  # server api
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts ++ [name: @name])
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end