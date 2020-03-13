defmodule SwiftApi.HttpClient do
  @moduledoc """
  Враппер HTTP клиента, с его помощью мы с наименьшими трудозатратами сможем
  менять Tesla/Poison/httpc etc либы местами, если будет необходимость
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
    client = Tesla.client([{Tesla.Middleware.Headers, headers}])

    client
    |> Tesla.put(url, options)
    |> tesla_response_to_app_response()
  end

  def put(url, body, headers \\ [], options \\ []) do
    client = Tesla.client([{Tesla.Middleware.Headers, headers}])

    client
    |> Tesla.put(url, body, options)
    |> tesla_response_to_app_response()
  end

  def post(url, body, headers \\ [], options \\ []) do
    client = Tesla.client([{Tesla.Middleware.Headers, headers}])

    client
    |> Tesla.post(url, body, options)
    |> tesla_response_to_app_response()
  end

  def delete(url, headers \\ [], options \\ []) do
    client = Tesla.client([{Tesla.Middleware.Headers, headers}])

    client
    |> Tesla.delete(url, options)
    |> tesla_response_to_app_response()
  end

  defp tesla_response_to_app_response(response_tuple) do
    case response_tuple do
      {:ok, %Tesla.Env{status: status, body: body, headers: headers}} ->
        {:ok, %Response{status_code: status, body: body, headers: downcase_headers_names(headers)}}

      {:error, reason} ->
        {:error, %Error{reason: reason}}
    end
  end

  # Функция преобразования названий заголовков в нижний регистр, чтобы уменьшить зависимость от
  # особенностей используемых http клиентов
  defp downcase_headers_names(headers) do
    Enum.map(headers, fn {key, value} ->
      {String.downcase(key), value}
    end)
  end
end
