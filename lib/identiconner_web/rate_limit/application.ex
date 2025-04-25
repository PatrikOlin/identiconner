defmodule IdenticonnerWeb.RateLimit.Application do
  @moduledoc """
  Application module for rate limiting functionality.
  Creates ETS table and starts cleanup process.
  """

  use GenServer
  require Logger

  @table_name :rate_limit_table
  @default_scale_ms 60_000 # 1 minute

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    scale_ms = Keyword.get(opts, :scale_ms, @default_scale_ms)

    Logger.info("Creating rate limit ETS table")
    :ets.new(@table_name, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])

    schedule_cleanup(scale_ms)

    {:ok, %{scale_ms: scale_ms}}
  end

  def handle_info(:cleanup, %{scale_ms: scale_ms} = state) do
    cleanup_old_entries(scale_ms)
    schedule_cleanup(scale_ms)
    {:noreply, state}
  end

  def cleanup_old_entries(scale_ms) do
    now = System.system_time(:millisecond)
    cutoff = now - scale_ms

    deleted = :ets.select_delete(@table_name, [{
						{:"$1", :"$2"},
						[{:<, :"$2", cutoff}],
						[true]
					      }])

    if deleted > 0 do
      Logger.debug("Cleaned up #{deleted} rate limit entries")
    end
  end

  defp schedule_cleanup(scale_ms) do
    Process.send_after(self(), :cleanup, div(scale_ms, 2))
  end
  
end
