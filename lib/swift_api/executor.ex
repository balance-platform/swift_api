defmodule SwiftApi.Executor do
  @moduledoc """
  Пример работы с api:
  ```
  client = %SwiftApi.Client{user_name: "os-auto-zenit-st1-partnerka",
  					  password: "jnAikmaSd0MNAsnd",
  					  domain_id: "af578a7d3daa49fe922100ff11581fc8",
  					  url: "https://auth.os.dc-cr.b-pl.pro",
  					  project_id: "b31fb563c0b644c8a6a6c1da43258e88",
  					  ca_certificate_path: "/mili/ca.crt",
  					  container: "bankproxy"}

  container = "mytest"
  filename = "test_data2.html"
  SwiftApi.Executor.object_temp_url(client, container, filename, 50)

  # создадим контейнер
  SwiftApi.Executor.create_container(client, "newc") # => {:ok, ""}
  # посмотрим назначенный на него ключ генерации временных ссылок - это же ключ и всего аккаунта по умолчанию
  SwiftApi.IdentityTokenWorker.get_temp_url_key("newc") # => "849df5780624b913595799ae01c90afe16a18a822b51b296"
  SwiftApi.IdentityTokenWorker.get_temp_url_key() # => "849df5780624b913595799ae01c90afe16a18a822b51b296"

  # прочитаем некий существующий файл
  SwiftApi.Executor.get(client, "mytest", "test_data.html") # => {:ok, "<html><body><p>Hello, test user!</p></body></html>"}
  # положим в существующий контейнер некоторые данные
  SwiftApi.Executor.put(client, "mytest", "test_data", "new data") # => {:ok, ""}
  # получим временную ссылку на этот новый файл
  SwiftApi.Executor.object_temp_url(client, "mytest", "test_data", 50) # => https://object.balance-pl.ru/v1/AUTH_b31fb563c0b644c8a6a6c1da43258e88/mytest/test_data?temp_url_sig=dc0bd2012170d00c06fc92903116261c58284717&temp_url_expires=1552555948
  # убедимся, что использовался ключ, заданный на этот ранее созданный контейнер
  SwiftApi.IdentityTokenWorker.get_temp_url_key("mytest") # => "some_key"
  ```
  """

  @doc """
  функция авторизации исполнителя (executor)

  в качестве параметра принимает структуру `SwiftApi.Client`

  перед использованием api обязательно должна быть вызвана с успешным завершением

  при неудачной аутентификации - когда код статуса отличен от 200, 201, 202, через три таких попытки возвращается ошибка
  """
  def identify(client, 3), do: {:error, "Can't authorize"}
  def identify(client, tries) do
    case identify(client) do
      {:ok, str} -> {:ok, str}
      {:error, _} -> identify(client, tries + 1)
    end
  end
  defp identify(client) do
    request_body = Poison.encode!(
      %{
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
    )

    identify_url = "#{client.url}/v3/auth/tokens"

    opts = case client.ca_certificate_path do
      nil -> []
      path -> [{:ssl_options, [{:cacertfile, path}]}]
    end

    headers = ["Content-Type": "application/json"]

    case HTTPoison.post(identify_url, request_body, headers, hackney: opts) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}}
      when status_code == 200 or status_code == 201 or status_code == 202 ->
        {"X-Subject-Token", token} = List.keyfind(headers, "X-Subject-Token", 0)
        SwiftApi.IdentityTokenWorker.update_token(token)
        SwiftApi.IdentityTokenWorker.update_identity_info(Poison.decode!(body))
        {:ok, "authorized"}
      error -> {:error, error}
    end
  end

  @doc """
  прочитать детали контейнера
  """
  def container_details(client), do: container_details(client, client.container)
  def container_details(client, container), do: get(client, container)

  @doc """
  создать при отсутствии контейнер
  """
  def create_container(client, container) do
    put(client, container, "")
  end

  @doc """
  прочитать детали аккаунта
  """
  def account_details(client), do: get(client, "")

  @doc """
  прочитать файл из хранилища

  - client - структура данных `SwiftApi.Client`
  - container - контейнер хранилища. при вызове с пустой строкой или nil в этом аргументе будет использован заданный client.container
  - file - имя файла в контейнере
  ```
  SwiftApi.Executor.get(%SwiftApi.Client{...}, nil, "fname") # => {:ok, "some-data-aaaa"}
  SwiftApi.Executor.get(%SwiftApi.Client{...}, "mytest", "test_data2.html") # => {:ok, "<html><body><p>user!!!!!111</p></body></html>"}
  ```

  **Важно!** контейнер не должен начинаться со слэша ("/")!
  """
  def get(client, "", file), do: get(client, "#{client.container}/#{file}")
  def get(client, nil, file), do: get(client, "#{client.container}/#{file}")
  def get(client, container, file), do: get(client, "#{container}/#{file}")
  @doc """
  прочитать файл из хранилища

  отличие от `get/3` в том, что вторым аргументом передаётся полный путь файла с хранилищем.

  ```
  SwiftApi.Executor.get(client, "mytest/test_data2.html") # => {:ok, "<html><body><p>user!!!!!111</p></body></html>"}
  ```

  **Важно!** путь к файлу не должен начинаться со слэша ("/")!
  """
  def get(client, path) do
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client, 0) do
          {:ok, _} -> _get(client, SwiftApi.IdentityTokenWorker.get_swift_url(), path)
          fail -> fail
        end
      swift_url -> _get(client, swift_url, path)
    end
  end

  @doc """
  положить файл в хранилище

  - client - структура данных `SwiftApi.Client`
  - container - контейнер хранилища. при вызове с пустой строкой или nil в этом аргументе будет использован заданный client.container
  - file - имя файла в контейнере
  - content - содержимое файла
  ```
  SwiftApi.Executor.put(%SwiftApi.Client{...}, nil, "fname", "some_data") # => {:ok, ""}
  SwiftApi.Executor.put(%SwiftApi.Client{...}, "mytest", "test_data2.html", "some_data") # => {:ok, ""}
  ```

  **Важно!** контейнер не должен начинаться со слэша ("/")!
  """
  def put(client, "", file, content), do: put(client, "#{client.container}/#{file}", content)
  def put(client, nil, file, content), do: put(client, "#{client.container}/#{file}", content)
  def put(client, container, file, content), do: put(client, "#{container}/#{file}", content)
  @doc """
  положить файл в хранилище

  отличие от `put/4` в том, что вторым аргументом передаётся полный путь файла с хранилищем.

  ```
  SwiftApi.Executor.put(client, "mytest/test_data2.html", "data") # => {:ok, ""}
  ```

  **Важно!** путь к файлу не должен начинаться со слэша ("/")!
  """
  def put(client, path, content) do
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client, 0) do
          {:ok, _} -> _put(client, SwiftApi.IdentityTokenWorker.get_swift_url(), path, content)
          fail -> fail
        end
      swift_url -> _put(client, swift_url, path, content)
    end
  end

  @doc """
  получить временную ссылку на файл

  - client - структура клиента swift, см. `SwiftApi.Client`
  - container - контейнер, где размещён файл. по умолчанию будет использован контейнер, заданный в клиенте (`client.container`)
  - file - имя файла, например, "filename.txt"
  - ttl - срок жизни ссылки. 60 - 1 минута, 60*60 = 3600 = 1 час, и т.д.

  ```
  SwiftApi.Worker.object_temp_url(client, container, filename, 60)
  # => "https://object.balance-pl.ru/v1/AUTH_somehash/mytest1_container1/test.txt?temp_url_sig=efa3e83eaa81a71d47350593d353f61af48506ba&temp_url_expires=1552462575"
  ```
  """
  def object_temp_url(client, file, ttl), do: object_temp_url(client, client.container, file, ttl)
  def object_temp_url(client, container, file, ttl), do: _object_temp_url(client, container, file, ttl)
  defp _object_temp_url(client, container, file, ttl) do
    # запрашиваем детали аккаунта и контейнера для получения temp_url_key на указанный контейнер или общий на аккаунт
    check_details_for_temp_key(client, container)
    [url, path] = SwiftApi.IdentityTokenWorker.get_swift_url() |> String.split("/v1/")
    filepath = "/v1/#{path}/#{container}/#{file}"
    {temp_url_sig, temp_url_expires} = temp_url_params(
      ttl,
      SwiftApi.IdentityTokenWorker.get_temp_url_key(container),
      filepath
    )
    "#{url}#{filepath}?temp_url_sig=#{temp_url_sig}&temp_url_expires=#{temp_url_expires}"
  end

  @doc """
  получить параметры для временной ссылки

  - ttl - время жизни ссылки, например, 60*60*24 = 86400 = 1 день
  - key - используемый ключ, в частности заголовок "X-Container-Meta-Temp-URL-Key"
  - url - путь до объекта, например: "/v1/AUTH_b31fb563c0b644c8a6a6c1da43258e88/mytest_container/test.txt"
  - method - тип запроса, по умолчанию GET

  в результате вернётся пара `{temp_url_sig, temp_url_expires}`
  """
  def temp_url_params(ttl, key, url, method \\ "GET") do
    temp_url_expires = :os.system_time(:seconds) + ttl
    temp_url_sig = :crypto.hmac(:sha, key, "#{method}\n#{temp_url_expires}\n#{url}")
                   |> Base.encode16
                   |> String.downcase
    {temp_url_sig, temp_url_expires}
  end

  # path должен быть в формате "контейнер/путь", т.е. начинаться НЕ со слэша
  defp _get(client, swift_url, path) do
    final_url = "#{swift_url}/#{path}"
    container = String.split(path, "/") |> Enum.at(0)
    headers = ["X-Auth-Token": SwiftApi.IdentityTokenWorker.get_token()]
    http_params = ["format": "json"]
    options = [params: http_params]
    case HTTPoison.get(final_url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}}
      when status_code == 200 or status_code == 201 or status_code == 202 ->
        set_temp_url_key(container, headers) # из заголовка сохраняем ключ генерации временных ссылок
        parse_json_body(body)
      {:ok, response} -> {:error, response}
      {:error, error} -> {:error, error}
    end
  end

  # path должен быть в формате "контейнер/путь", т.е. начинаться НЕ со слэша
  defp _put(client, swift_url, path, content) do
    final_url = "#{swift_url}/#{path}"
    container = String.split(path, "/") |> Enum.at(0)
    # вызываем детали контейнера/аккаунта для получения информации о ключе генерации временной ссылки
    check_details_for_temp_key(client, container)
    headers = [
      "X-Auth-Token": SwiftApi.IdentityTokenWorker.get_token(),
      "X-Container-Meta-Temp-URL-Key": SwiftApi.IdentityTokenWorker.get_temp_url_key(container)
    ]
    http_params = ["format": "json"]
    options = [params: http_params]
    case HTTPoison.put(final_url, content, headers, options) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}}
      when status_code == 200 or status_code == 201 or status_code == 202 -> parse_json_body(body)
      {:ok, response} -> {:error, response}
      {:error, error} -> {:error, error}
    end
  end

  # вынуть и сохранить из заголовка ключ генерации временной ссылки контейнера или аккаунта
  defp set_temp_url_key(container, headers) do
    case List.keyfind(headers, "X-Container-Meta-Temp-Url-Key", 0) || List.keyfind(headers, "X-Account-Meta-Temp-Url-Key", 0) do
      {_, temp_url_key} -> SwiftApi.IdentityTokenWorker.update_temp_url_key(container, temp_url_key)
      nil -> nil
    end
  end

  # запрашиваем детали аккаунта и детали конкретного контейнера. в результате вызова деталей сохранится заданный заголовочный ключ
  # генерации временной ссылки - "X-Container-Meta-Temp-Url-Key" для контейнера и "X-Account-Meta-Temp-Url-Key" для аккаунта
  defp check_details_for_temp_key(client, container) do
    account_details(client)
    container_details(client, container)
  end

  defp parse_json_body(body) do
    case Poison.decode(body) do
      {:ok, map} -> {:ok, map}
      {:error, descr} -> {:ok, body}
      {:error, :invalid, descr} -> {:ok, body}
    end
  end
end