defmodule Cannery.LoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Cannery.Logger, as: CanneryLogger

  describe "handle_event/4 for [:oban, :job, :exception]" do
    test "handles reason that does not implement String.Chars" do
      # Oban.PerformError doesn't implement String.Chars, which caused
      # the handler to crash in prod. This test ensures we handle it.
      reason = %Oban.PerformError{
        message: "SomeWorker failed with {:error, :timeout}",
        reason: {:error, :timeout}
      }

      meta = %{
        reason: reason,
        stacktrace: [],
        job: %Oban.Job{
          id: 1,
          args: %{},
          meta: %{},
          queue: "default",
          worker: "SomeWorker"
        }
      }

      log =
        capture_log(fn ->
          CanneryLogger.handle_event([:oban, :job, :exception], %{duration: 100}, meta, nil)
        end)

      assert log =~ "SomeWorker failed with {:error, :timeout}"
    end

    test "handles plain tuple reason" do
      meta = %{
        reason: {:error, :some_failure},
        stacktrace: [],
        job: %Oban.Job{
          id: 2,
          args: %{},
          meta: %{},
          queue: "default",
          worker: "SomeWorker"
        }
      }

      log =
        capture_log(fn ->
          CanneryLogger.handle_event([:oban, :job, :exception], %{duration: 100}, meta, nil)
        end)

      assert log =~ "some_failure"
    end
  end
end
