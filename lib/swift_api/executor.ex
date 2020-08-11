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
  SwiftApi.Executor.object_temp_url(client, "mytest", "test_data", 50) # => object_temp_url # строка
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
  def identify(_client, 3), do: {:error, "Can't authorize"}

  def identify(client, tries) do
    case identify(client) do
      {:ok, str} -> {:ok, str}
      {:error, _} -> identify(client, tries + 1)
    end
  end

  defp identify(client) do
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
        case identify(client, 0) do
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

      swift_url ->
        _get(client, swift_url, path)
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

      swift_url ->
        _put(client, swift_url, path, content)
    end
  end

  def delete(client, container, file) do
    path = Path.join([container, file])

    case SwiftApi.IdentityTokenWorker.get_swift_url() do
      nil ->
        case identify(client, 0) do
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
  # => "https://object.someurl.pro/v1/AUTH_somehash/mytest1_container1/test.txt?temp_url_sig=efa3e83eaa81a71d47350593d353f61af48506ba&temp_url_expires=1552462575"
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
  - url - путь до объекта, например: "/v1/AUTH_b31fb563c0b644c8a6a6c1da43258e88/mytest_container/test.txt"
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
    container = String.split(path, "/") |> Enum.at(0)

    headers = [
      {"accept", "application/json"},
      {"x-auth-token", SwiftApi.IdentityTokenWorker.get_token()}
    ]

    case HttpClient.head(final_url, headers, []) do
      {:ok, response = %Tesla.Env{status: status_code, headers: headers}}
      when status_code == 200 or status_code == 201 or status_code == 202 ->
        # из заголовка сохраняем ключ генерации временных ссылок
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
      {:ok, %HttpClient.Response{status_code: status_code, body: body, headers: headers}}
      when status_code == 200 or status_code == 201 or status_code == 202 ->
        # из заголовка сохраняем ключ генерации временных ссылок
        set_temp_url_key(container, headers)
        parse_json_body(body)

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

    headers = [
      {"accept", "application/json"},
      {"x-auth-token", SwiftApi.IdentityTokenWorker.get_token()},
      {"x-container-meta-temp-url-key", SwiftApi.IdentityTokenWorker.get_temp_url_key(container)}
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
      {:ok, http_resposne_struct} -> {:error, http_resposne_struct}
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
