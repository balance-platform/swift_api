defmodule SwiftApi.HttpClient do
  @moduledoc """
  Враппер HTTP клиента, с его помощью мы с наименьшими трудозатратами сможем
  менять Tesla/Poison/httpc etc библиотеки местами, если будет необходимость
  """
  defmodule Response do
    @moduledoc false
    defstruct status_code: nil, body: nil, headers: []
  end

  defmodule Error do
    @moduledoc false
    defstruct reason: nil
  end

  def get(url, headers \\ [], options \\ []) do
    client = build_client(headers, options)

    client
    |> Tesla.get(url, options)
    |> tesla_response_to_app_response()
  end

  def head(url, headers \\ [], options \\ []) do
    client = build_client(headers, options)

    client
    |> Tesla.head(url, options)
  end

  def put(url, body, headers \\ [], options \\ []) do
    client = build_client(headers, options)

    client
    |> Tesla.put(url, body, options)
    |> tesla_response_to_app_response()
  end

  def post(url, body, headers \\ [], options \\ []) do
    client = build_client(headers, options)
    client
    |> Tesla.post(url, body, options)
    |> tesla_response_to_app_response()
  end

  def delete(url, headers \\ [], options \\ []) do
    client = build_client(headers, options)

    client
    |> Tesla.delete(url, options)
    |> tesla_response_to_app_response()
  end

  defp build_client(headers, options) do
    timeout = Keyword.get(options, :timeout, 10_000)

    Tesla.client([
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.Timeout, [timeout: timeout]}
    ], {Tesla.Adapter.Hackney, [:insecure]})
  end

  defp tesla_response_to_app_response(response_tuple) do
    case response_tuple do
      {:ok, %Tesla.Env{status: status, body: body, headers: headers}} ->
        {:ok,
         %Response{status_code: status, body: body, headers: down_case_headers_names(headers)}}

      {:error, reason} ->
        {:error, %Error{reason: reason}}
    end
  end

  # Функция преобразования названий заголовков в нижний регистр, чтобы уменьшить зависимость от
  # особенностей используемых http клиентов
  defp down_case_headers_names(headers) do
    Enum.map(headers, fn {key, value} ->
      {String.downcase(key), value}
    end)
  end
end
