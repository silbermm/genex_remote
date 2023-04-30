defmodule GenexRemoteWeb.SessionControllerTest do
  use GenexRemoteWeb.ConnCase

  alias GenexRemote.Auth.Account
  alias GenexRemote.Repo

  describe "login with one time token" do
    setup :setup_one_time_token

    test "successful login", %{conn: conn, token: token, email: email} do
      conn = get(conn, "/login/#{token}/email/#{email}")

      assert redirected_to(conn) =~ Routes.home_index_path(conn, :index)
      assert get_flash(conn, :info) == "Welcome back"

      refute is_nil(get_session(conn, :auth_token))
    end

    test "writes audit log", %{conn: conn, account: account, token: token, email: email} do
      conn = get(conn, "/login/#{token}/email/#{email}")

      assert redirected_to(conn) == Routes.home_index_path(conn, :index)
      assert get_flash(conn) == %{"info" => "Welcome back"}

      audit_log =
        Repo.get_by(GenexRemote.Audits.AuditLog, account_id: account.id, action: :logged_in)

      assert audit_log
    end

    test "invalid token fails login", %{conn: conn, token: token, email: email} do
      conn = get(conn, "/login/#{token}bad/email/#{email}")

      assert redirected_to(conn) =~ Routes.home_index_path(conn, :index)
      assert get_flash(conn, :error) == "Invalid login"

      assert is_nil(get_session(conn, :auth_token))
    end

    test "invalid email fails login", %{conn: conn, token: token, email: email} do
      conn = get(conn, "/login/#{token}/email/#{email}bad")

      assert redirected_to(conn) =~ Routes.home_index_path(conn, :index)
      assert get_flash(conn, :error) == "Invalid login"

      assert is_nil(get_session(conn, :auth_token))
    end
  end

  defp setup_one_time_token(_context) do
    email = "test@test.com"
    token = Account.generate_login_token()

    {:ok, account} =
      %Account{}
      |> Ecto.Changeset.cast(%{email: email}, [:email])
      |> Account.token_changeset(%{
        email: email,
        public_key: "1234",
        login_token: token
      })
      |> Ecto.Changeset.change(%{
        validated: DateTime.truncate(DateTime.utc_now(), :second)
      })
      |> Repo.primary_write(:insert)

    %{account: account, token: token, email: email}
  end
end
