defmodule Cannery.EmailWorkerTest do
  use Cannery.DataCase, async: true

  def perform_job(worker, args) do
    Oban.Testing.perform_job(worker, args, [])
  end

  test "sending welcome email" do
    user = user_fixture()

    {:ok, _user} =
      perform_job(Cannery.EmailWorker, %{
        "email" => "welcome",
        "user_id" => user.id,
        "attrs" => %{"url" => "test_url"}
      })
  end

  test "sending reset password email" do
    user = user_fixture()

    {:ok, _user} =
      perform_job(Cannery.EmailWorker, %{
        "email" => "reset_password",
        "user_id" => user.id,
        "attrs" => %{"url" => "test_url"}
      })
  end

  test "sending update email email" do
    user = user_fixture()

    {:ok, _user} =
      perform_job(Cannery.EmailWorker, %{
        "email" => "update_email",
        "user_id" => user.id,
        "attrs" => %{"url" => "test_url"}
      })
  end
end
