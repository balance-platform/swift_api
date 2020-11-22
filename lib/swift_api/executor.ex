defmodule SwiftApi.Executor do
  require Logger

  alias SwiftApi.HttpClient

  @moduledoc """
  Пример работы с api:
  ```
  client = %SwiftApi.Client{user_name: "stage-user",
  					  password: "password",
  					  domain_id: "domain_id",
  					  url: "url",
  					  project_id: "project_id",
  					  ca_certificate_path: ca_certificate_path,
  					  container: container_name}

  container = "my_test"
  filename = "test_data2.html"
  SwiftApi.Executor.object_temp_url(client, container, filename, 50)

  # создадим контейнер
  SwiftApi.Executor.create_container(client, "new_container") # => {:ok, ""}
  # посмотрим назначенный на него ключ генерации временных ссылок - это же ключ и всего аккаунта по умолчанию
  SwiftApi.IdentityTokenWorker.get_temp_url_key("new_container") # => "849df5780624b913595799ae01c90afe16a18a822b51b296"
  SwiftApi.IdentityTokenWorker.get_temp_url_key() # => "849df5780624b913595799ae01c90afe16a18a822b51b296"

  # прочитаем некий существующий файл
  SwiftApi.Executor.get(client, "my_test", "test_data.html") # => {:ok, "<html><body><p>Hello, test user!</p></body></html>"}
  # положим в существующий контейнер некоторые данные
  SwiftApi.Executor.put(client, "my_test", "test_data", "new data") # => {:ok, ""}
  # получим временную ссылку на этот новый файл
  SwiftApi.Executor.object_temp_url(client, "my_test", "test_data", 50) # => object_temp_url # строка
  # убедимся, что использовался ключ, заданный на этот ранее созданный контейнер
  SwiftApi.IdentityTokenWorker.get_temp_url_key("my_test") # => "some_key"
  ```
  """

  @doc """
  функция авторизации исполнителя (executor)

  в качестве параметра принимает структуру `SwiftApi.Client`

  перед использованием api обязательно должна быть вызвана с успешным завершением

  при неудачной аутентификации - когда код статуса отличен от 200, 201, 202, через три таких попытки возвращается ошибка
  """
  def identify(client), do: identify(client, 0)
  def identify(_client, 3), do: {:error, "Can't authorize"}

  def identify(client, tries) do
    case identify_work(client) do
      {:ok, str} -> {:ok, str}
      {:error, _} -> identify(client, tries + 1)
    end
  end

  defp identify_work(client) do
    request_body =
      Poison.encode!(%{
        auth: %{
          identity: %{
            methods: ["password"],
            password: %{
              user: %{
                name: client.user_name,
                password: client.password,
                domain: %{
                  name: client.domain_name
                }
              }
            }
          },
          scope: %{
            project: %{
              id: client.project_id
            }
          }
        }
      })

    identify_url = "#{client.url}/v3/auth/tokens"

    opts =
      case client.ca_certificate_path do
        nil -> []
        path -> [ssl_options: [certfile: path]]
      end

    headers = [{"content-type", "application/json"}]

    case HttpClient.post(identify_url, request_body, headers, opts) do
      {:ok, %SwiftApi.HttpClient.Response{status_code: status_code, body: body, headers: headers}}
      when status_code == 200 or status_code == 201 or status_code == 202 ->
        {"x-subject-token", token} = List.keyfind(headers, "x-subject-token", 0)
        SwiftApi.IdentityTokenWorker.update_token(token)
        SwiftApi.IdentityTokenWorker.update_identity_info(Poison.decode!(body))
        {:ok, "authorized"}

      {:error, %HttpClient.Error{reason: :nxdomain}} ->
        Logger.error("NXDOMAIN error for: #{identify_url}. Check nslookup -type=ns _domain_")
        {:error, :nxdomain}

      error ->
        Logger.error("#{identify_url}: #{inspect(error)}")
        {:error, error}
    end
  end

  def get_n_minute_valid_token(client, n) do
    now = Timex.now()

    case SwiftApi.IdentityTokenWorker.check_time_validity(Timex.shift(now, minutes: -1 * n)) do
      true ->
        SwiftApi.IdentityTokenWorker.get_token()

      false ->
        {:ok, _} = SwiftApi.Executor.identify(client)
        SwiftApi.IdentityTokenWorker.get_token()
    end
  end

  @doc """
  прочитать детали контейнера
  """
  def container_details(client, container \\ nil) do
    get(client, container || client.container)
  end

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

  def head(client, path) do
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client) do
          {:ok, _} -> _head(client, SwiftApi.IdentityTokenWorker.get_swift_url(), path)
          fail -> fail
        end

      swift_url ->
        _head(client, swift_url, path)
    end
  end

  @doc """
  прочитать файл из хранилища

  - client - структура данных `SwiftApi.Client`
  - container - контейнер хранилища. при вызове с пустой строкой или nil в этом аргументе будет использован заданный client.container
  - file - имя файла в контейнере
  ```
  SwiftApi.Executor.get(%SwiftApi.Client{...}, nil, "first_name") # => {:ok, "some-data-aaaa", metadata}
  SwiftApi.Executor.get(%SwiftApi.Client{...}, "my_test", "test_data2.html") # => {:ok, "<html><body><p>user!!!!!111</p></body></html>", metadata}
  ```

  **Важно!** контейнер не должен начинаться со слэша ("/")!
  """
  def get(client, container, file) do
    path =
      case container do
        "" -> "#{client.container}/#{file}"
        nil -> "#{client.container}/#{file}"
        _container_set -> "#{container}/#{file}"
      end

    get(client, path)
  end

  @doc """
  прочитать файл из хранилища

  отличие от `get/3` в том, что вторым аргументом передаётся полный путь файла с хранилищем.

  ```
  SwiftApi.Executor.get(client, "my_test/test_data2.html") # => {:ok, "<html><body><p>user!!!!!111</p></body></html>"}
  ```

  **Важно!** путь к файлу не должен начинаться со слэша ("/")!
  """
  def get(client, path) do
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client) do
          {:ok, _} -> _get(client, SwiftApi.IdentityTokenWorker.get_swift_url(), path)
          fail -> fail
        end

      swift_url ->
        _get(client, swift_url, path)
    end
  end

  @doc """
  Обновить метаданные файла в хранилище

  - client - структура данных `SwiftApi.Client`
  - container - контейнер хранилища. при вызове с пустой строкой или nil в этом аргументе будет использован заданный client.container
  - file - имя файла в контейнере
  - headers - метаданные
  ```
  SwiftApi.Executor.post(%SwiftApi.Client{...}, nil, "first_name", ["X-Object-Meta-{name}": value]) # => {:ok, [metadata]}

  # Пример ответа:
  {:ok,
  [
    {"content-length", "76"},
    {"content-type", "text/html; charset=UTF-8"},
    {"x-trans-id", "tx815c30837ddc4c6f89aac-005fb979ca"},
    {"x-openstack-request-id", "tx815c30837ddc4c6f89aac-005fb979ca"},
    {"date", "Sat, 21 Nov 2020 20:34:18 GMT"}
  ]}
  ```

  **Важно!** контейнер не должен начинаться со слэша ("/")!
  """
  def post(client, container, file, headers) when is_list(headers) do
    path =
      case container do
        "" -> "#{client.container}/#{file}"
        nil -> "#{client.container}/#{file}"
        _container_set -> "#{container}/#{file}"
      end

    post(client, path, headers)
  end

  def post(client, path, headers) do
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client) do
          {:ok, _} -> _post(client, SwiftApi.IdentityTokenWorker.get_swift_url(), path, headers)
          fail -> fail
        end

      swift_url ->
        _post(client, swift_url, path, headers)
    end
  end

  @doc """
  положить файл в хранилище

  - client - структура данных `SwiftApi.Client`
  - container - контейнер хранилища. при вызове с пустой строкой или nil в этом аргументе будет использован заданный client.container
  - file - имя файла в контейнере
  - content - содержимое файла
  ```
  SwiftApi.Executor.put(%SwiftApi.Client{...}, nil, "first_name", "some_data") # => {:ok, ""}
  SwiftApi.Executor.put(%SwiftApi.Client{...}, "my_test", "test_data2.html", "some_data") # => {:ok, ""}
  ```

  **Важно!** контейнер не должен начинаться со слэша ("/")!
  """
  def put(client, container, file, content) do
    path =
      case container do
        "" -> "#{client.container}/#{file}"
        nil -> "#{client.container}/#{file}"
        _container_set -> "#{container}/#{file}"
      end

    put(client, path, content)
  end

  @doc """
  положить файл в хранилище

  отличие от `put/4` в том, что вторым аргументом передаётся полный путь файла с хранилищем.

  ```
  SwiftApi.Executor.put(client, "my_test/test_data2.html", "data") # => {:ok, ""}
  ```

  **Важно!** путь к файлу не должен начинаться со слэша ("/")!
  """
  def put(client, path, content) do
    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client) do
          {:ok, _} -> _put(client, SwiftApi.IdentityTokenWorker.get_swift_url(), path, content)
          fail -> fail
        end

      swift_url ->
        _put(client, swift_url, path, content)
    end
  end

  def delete(client, container, file) do
    path = Path.join([container, file])

    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client) do
          {:ok, _} -> _delete(client, SwiftApi.IdentityTokenWorker.get_swift_url(), path)
          fail -> fail
        end

      swift_url ->
        _delete(client, swift_url, path)
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
  # => "https://object.someurl.pro/v1/AUTH_somehash/my_test1_container1/test.txt?temp_url_sig=efa3e83eaa81a71d47350593d353f61af48506ba&temp_url_expires=1552462575"
  ```
  """
  def object_temp_url(client, file, ttl), do: object_temp_url(client, client.container, file, ttl)

  def object_temp_url(client, container, file, ttl),
    do: _object_temp_url(client, container, file, ttl)

  defp _object_temp_url(client, container, file, ttl) do
    # запрашиваем детали аккаунта и контейнера для получения temp_url_key на указанный контейнер или общий на аккаунт
    check_details_for_temp_key(client, container)

    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        nil

      swift_url ->
        [url, path] = String.split(swift_url, "/v1/")
        filepath = "/v1/#{path}/#{container}/#{file}"

        {temp_url_sig, temp_url_expires} =
          temp_url_params(
            ttl,
            SwiftApi.IdentityTokenWorker.get_temp_url_key(container),
            filepath
          )

        "#{url}#{filepath}?temp_url_sig=#{temp_url_sig}&temp_url_expires=#{temp_url_expires}"
    end
  end

  @doc """
  получить параметры для временной ссылки

  - ttl - время жизни ссылки, например, 60*60*24 = 86400 = 1 день
  - key - используемый ключ, в частности заголовок "X-Container-Meta-Temp-URL-Key"
  - url - путь до объекта, например: "/v1/AUTH_b31fb563c0b644c8a6a6c1da43258e88/my_test_container/test.txt"
  - method - тип запроса, по умолчанию GET

  в результате вернётся пара `{temp_url_sig, temp_url_expires}`
  """
  def temp_url_params(ttl, key, url, method \\ "GET") do
    temp_url_expires = :os.system_time(:seconds) + ttl

    temp_url_sig =
      :crypto.hmac(:sha, key, "#{method}\n#{temp_url_expires}\n#{url}")
      |> Base.encode16()
      |> String.downcase()

    {temp_url_sig, temp_url_expires}
  end

  # path должен быть в формате "контейнер/путь", т.е. начинаться НЕ со слэша
  defp _head(_client, swift_url, path) do
    final_url = "#{swift_url}/#{path}"

    headers = [
      {"accept", "application/json"},
      {"x-auth-token", SwiftApi.IdentityTokenWorker.get_token()}
    ]

    case HttpClient.head(final_url, headers, []) do
      {:ok, %SwiftApi.HttpClient.Response{status_code:status_code, headers: headers}}
      when status_code == 200 or status_code == 201 or status_code == 202 ->
        {:ok, headers}

      {:ok, response} ->
        {:error, response}

      {:error, error} ->
        {:error, error}
    end
  end

  # path должен быть в формате "контейнер/путь", т.е. начинаться НЕ со слэша
  defp _get(_client, swift_url, path) do
    final_url = "#{swift_url}/#{path}"
    container = String.split(path, "/") |> Enum.at(0)

    headers = [
      {"accept", "application/json"},
      {"x-auth-token", SwiftApi.IdentityTokenWorker.get_token()}
    ]

    case HttpClient.get(final_url, headers, []) do
      {:ok, %HttpClient.Response{status_code: status_code, body: body, headers: metadata}}
      when status_code == 200 or status_code == 201 or status_code == 202 ->
        set_temp_url_key(container, headers)
        {:ok, data} = parse_json_body(body)

        {:ok, data, metadata}

      {:ok, response} ->
        {:error, response}

      {:error, error} ->
        {:error, error}
    end
  end

  # path должен быть в формате "контейнер/путь", т.е. начинаться НЕ со слэша
  defp _put(client, swift_url, path, content) do
    final_url = "#{swift_url}/#{path}"
    container = String.split(path, "/") |> Enum.at(0)

    # вызываем детали контейнера/аккаунта для получения информации о ключе генерации временной ссылки
    check_details_for_temp_key(client, container)

    headers =
      [
        {"accept", "application/json"},
        {"x-auth-token", SwiftApi.IdentityTokenWorker.get_token()},
        {"x-container-meta-temp-url-key",
         SwiftApi.IdentityTokenWorker.get_temp_url_key(container)}
      ]

    case HttpClient.put(final_url, content, headers, []) do
      {:ok, %HttpClient.Response{status_code: status_code, body: body} = response} ->
        if status_code in [200, 201, 202] do
          parse_json_body(body)
        else
          {:error, response}
        end

      {:ok, response} ->
        {:error, response}

      {:error, error} ->
        {:error, error}
    end
  end

  # path должен быть в формате "контейнер/путь", т.е. начинаться НЕ со слэша
  defp _post(client, swift_url, path, additional_meta_headers) do
    final_url = "#{swift_url}/#{path}"

    metadata_for_save =
      [
        {"x-auth-token", SwiftApi.IdentityTokenWorker.get_token()},
      ] ++ additional_meta_headers

    case HttpClient.post(final_url, "", metadata_for_save) do
      {:ok, %HttpClient.Response{status_code: 202, body: body, headers: object_metadata} = response} ->
        {:ok, object_metadata}

      {:ok, response} ->
        {:error, response}

      {:error, error} ->
        {:error, error}
    end
  end

  # path должен быть в формате "контейнер/путь", т.е. начинаться НЕ со слэша
  defp _delete(client, swift_url, path) do
    final_url = "#{swift_url}/#{path}"
    container = client.container

    headers = [
      {"accept", "application/json"},
      {"x-auth-token", SwiftApi.IdentityTokenWorker.get_token()},
      {"x-container-meta-temp-url-key", SwiftApi.IdentityTokenWorker.get_temp_url_key(container)}
    ]

    case HttpClient.delete(final_url, headers, []) do
      {:ok, %HttpClient.Response{status_code: 204} = response} -> {:ok, response}
      {:error, error} -> {:error, error}
      {:ok, http_response_struct} -> {:error, http_response_struct}
    end
  end

  # вынуть и сохранить из заголовка ключ генерации временной ссылки контейнера или аккаунта
  defp set_temp_url_key(container, headers) do
    case List.keyfind(headers, "x-container-meta-temp-url-key", 0) ||
           List.keyfind(headers, "x-account-meta-temp-url-key", 0) do
      {_, temp_url_key} ->
        SwiftApi.IdentityTokenWorker.update_temp_url_key(container, temp_url_key)

      nil ->
        nil
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
      {:error, _descr} -> {:ok, body}
      {:error, :invalid, _descr} -> {:ok, body}
    end
  end
end
