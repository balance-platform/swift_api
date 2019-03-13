defmodule SwiftApi.IdentityTokenWorker do
  @moduledoc false
  
  use Agent

  def start_link(_state, _opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def update_token(token), do: Agent.update(__MODULE__, & Map.merge(&1, %{token: token}))

  def get_token do
    data = Agent.get(__MODULE__, & &1)
    data[:token]
  end

  @doc """
  установить ключ генерации временных ссылок для указанного контейнера.

  имеется в виду заголовок "X-Container-Meta-Temp-Url-Key" в случае для конкретного контейнера,
  или "X-Account-Meta-Temp-Url-Key" в случае общего ключа на всём аккаунте.

  в случае, когда первый параметр - контейнер - nil или пустая строка, устанавливается общий ключ,
  который по идее должен браться из информации всего аккаунта.
  в таком случае сохранение производится в корневой `temp_url_key`.

  если указан конкретный контейнер, сохранение будет произведено в `container_name->temp_url_key`
  """
  def update_temp_url_key("", temp_url_key) do
    Agent.update(__MODULE__, & Map.merge(&1, %{temp_url_key: temp_url_key}))
  end
  def update_temp_url_key(nil, temp_url_key), do: update_temp_url_key("", temp_url_key)
  def update_temp_url_key(container, temp_url_key) do
    Agent.update(__MODULE__, & Map.merge(&1, %{container => %{temp_url_key: temp_url_key}}))
  end

  @doc """
  вернуть ключ генерации временных ссылок для указанного контейнера.

  имеется в виду заголовок "X-Container-Meta-Temp-Url-Key" в случае для конкретного контейнера,
  или "X-Account-Meta-Temp-Url-Key" в случае общего ключа на всём аккаунте.

  В случае, когда по конкретному контейнеру взять ключ не удаётся, или функция вызывается без
  параметров (или контейнером-пустой строкой), возвращается (при наличии) ключ аккаунта.
  """
  def get_temp_url_key do
    data = Agent.get(__MODULE__, & &1)
    data[:temp_url_key]
  end
  def get_temp_url_key(""), do: get_temp_url_key()
  def get_temp_url_key(container) do
    data = Agent.get(__MODULE__, & &1)
    case data[container][:temp_url_key] do
      nil -> get_temp_url_key()
      key -> key
    end
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

  def update_identity_info(info), do: Agent.update(__MODULE__, & Map.merge(&1, %{identity: info}))

  def get_identity_info do
    data = Agent.get(__MODULE__, & &1)
    data[:identity]
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