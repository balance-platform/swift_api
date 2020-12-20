defmodule SwiftApi.Genstage.ObjectIterator do
  use GenStage

  defstruct client: nil,
    downloaded_count: -1,
    start_from: nil,
    container: nil

  def start_link([client, container]), do: start_link(client, container)

  def start_link(client, container) do
    mem = %__MODULE__{client: client, container: container}
    state = [mem, []]

    name = "#{__MODULE__}_#{container}"
    GenStage.start_link(__MODULE__, state, name: String.to_atom(name))
  end

  def init(state), do: {:producer, state}

  def handle_demand(demand, [mem, list]) do
    with {:length, true} <- {:length, length(list) < demand},
         {:downloaded_count, true} <- {:downloaded_count, mem.downloaded_count == -1 or mem.downloaded_count == 10_000},
         {:ok, new_list} <- container_get(mem.client, mem.container, %{marker: mem.start_from}),
         downloaded_count <- length(new_list)
    do
      last_element = List.last(new_list)
      new_mem = %{mem | start_from: last_element["name"], downloaded_count: downloaded_count}
      new_urls = new_list |> Enum.map(& Map.put(&1, :container, mem.container))
      new_list = list ++ new_urls

      {res, remaining} = Enum.split(new_list, demand)
      {:noreply, res, [new_mem, remaining]}

    else
      {:downloaded_count, false} ->
        case length(list) do
          0 ->
            GenStage.async_info(self(), {:producer, :done})
            {:noreply, [], [mem, []]}
          _ ->
            {res, remaining} = Enum.split(list, demand)
            {:noreply, res, [mem, remaining]}
        end

      {:length, false} ->
        {res, remaining} = Enum.split(list, demand)
        {:noreply, res, [mem, remaining]}

      smth ->
        log = '** Error in handle_demand in ~tp~n, but we continue. ** Unhandled message: ~tp~n**'
        :error_logger.warning_msg(log, [inspect(__MODULE__), inspect(smth)])

        {res, remaining} = Enum.split(list, demand)
        {:noreply, res, [mem, remaining]}
    end
  end

  def container_get(client, container, options, tries \\ 10)

  def container_get(client, container, options, 0) do
    case SwiftApi.Executor.container_get(client, container, options) do
      {:ok, res} -> {:ok, res}
      {:error, res} -> {:error, res}
    end
  end

  def container_get(client, container, options, tries) do
    case SwiftApi.Executor.container_get(client, container, options) do
      {:ok, res} -> {:ok, res}
      {:error, %SwiftApi.HttpClient.Error{reason: :timeout}} ->
        Process.sleep(2000)
        container_get(client, container, options, tries - 1)
    end
  end

  def handle_info({:producer, :done}, state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    log = '** Undefined handle_info in ~tp~n** Unhandled message: ~tp~n** Stream started at:'
    :error_logger.warning_msg(log, [inspect(__MODULE__), msg])
    {:noreply, [], state}
  end
end
