defmodule ArchitectureA1.OpenSearchManager do
  use GenServer
  require Logger

  @opensearch_url "http://opensearch:9200"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def available?() do
    case GenServer.call(__MODULE__, :get_availability) do
      status when is_boolean(status) -> status
      _ -> false
    end
  rescue
    _ -> false
  end

  @impl true
  def init(_) do
    available = check_opensearch_connection()
    Logger.info("OpenSearch availability checked at startup: #{available}")

    {:ok, %{available: available}}
  end

  @impl true
  def handle_call(:get_availability, _from, state) do
    {:reply, state.available, state}
  end

  defp check_opensearch_connection() do
    Logger.info("Checking OpenSearch connection at #{@opensearch_url}...")

    case Req.get(@opensearch_url, connect_options: [timeout: 10000]) do
      {:ok, %{status: 200}} ->
        Logger.info("OpenSearch is available")
        true
      {:ok, %{status: status}} ->
        Logger.warning("OpenSearch responded with status #{status}")
        false
      {:error, reason} ->
        Logger.info("OpenSearch not available: #{inspect(reason)}")
        false
    end
  rescue
    e ->
      Logger.info("OpenSearch connection failed: #{inspect(e)}")
      false
  end
end
