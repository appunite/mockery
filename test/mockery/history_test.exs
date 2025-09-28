defmodule Mockery.HistoryTest do
  use ExUnit.Case
  use Mockery

  import IO.ANSI

  alias Mockery.Utils

  test "enable_history/0" do
    Mockery.History.enable_history()

    assert Process.get(Mockery.History)
  end

  test "disable_history/0" do
    Mockery.History.disable_history()

    refute Process.get(Mockery.History)
  end

  describe "enabled?/0" do
    test "returns true by default" do
      assert Mockery.History.enabled?()
    end

    test "can be changed by global config" do
      Application.put_env(:mockery, :history, false)
      on_exit(fn -> Application.delete_env(:mockery, :history) end)

      refute Mockery.History.enabled?()
    end

    test "ignores global config when process config present" do
      Application.put_env(:mockery, :history, false)
      on_exit(fn -> Application.delete_env(:mockery, :history) end)

      Mockery.History.enable_history()

      assert Mockery.History.enabled?()
    end
  end

  describe "print/1 when history is disabled" do
    test "error message doesn't include calls history" do
      Mockery.History.disable_history()

      error_msg = "#{red()}Foo.bar/2 was not called with given args"

      Utils.push_call(Foo, :bar, 1, [1])
      Utils.push_call(Foo, :bar, 2, [1, 3])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, 2]
        end

      assert error.message == error_msg
    end
  end

  describe "print/1 when history is enabled (args provided)" do
    test "single call not matching args" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args

      #{yellow()}Given:#{reset()}
      [1, 2]

      #{yellow()}History:#{reset()}
      args: [1, #{green()}2#{reset()}]
      call: [1, #{red()}3#{reset()}]
      """

      Utils.push_call(Foo, :bar, 2, [1, 3])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, 2]
        end

      assert error.message == error_msg
    end

    test "multiple calls not matching args" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args

      #{yellow()}Given:#{reset()}
      [1, 2]

      #{yellow()}History:#{reset()}
      args: [1, #{green()}2#{reset()}]
      call: [1, #{red()}3#{reset()}]

      args: [#{green()}1#{reset()}, 2]
      call: [2, #{red()}2#{reset()}]
      """

      Utils.push_call(Foo, :bar, 2, [1, 3])
      Utils.push_call(Foo, :bar, 2, [2, 2])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, 2]
        end

      assert error.message == error_msg
    end

    test "no calls matching args" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args

      #{yellow()}Given:#{reset()}
      [1, 2]

      #{yellow()}History:#{reset()}
      (#{light_yellow()}#{underline()}empty - no function calls were registered#{reset()})
      """

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, 2]
        end

      assert error.message == error_msg
    end

    test "one call matching, one not (times: 2)" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args expected number of times

      #{yellow()}Given:#{reset()}
      [1, 2]

      #{yellow()}History:#{reset()}
      args: [1, 2]
      call: [1, 2]

      args: [#{green()}1#{reset()}, 2]
      call: [#{red()}3#{reset()}, 2]
      """

      Utils.push_call(Foo, :bar, 2, [1, 2])
      Utils.push_call(Foo, :bar, 2, [3, 2])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, 2], times: 2
        end

      assert error.message == error_msg
    end

    test "one call with pinned variable" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args expected number of times

      #{yellow()}Given:#{reset()}
      [1, ^asdf]

      asdf = 2

      #{yellow()}History:#{reset()}
      args: [#{green()}1#{reset()}, ^asdf]
      call: [#{red()}3#{reset()}, 2]
      """

      Utils.push_call(Foo, :bar, 2, [3, 2])

      asdf = 2

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, ^asdf], times: 2
        end

      assert error.message == error_msg
    end

    @asdf 2
    test "one call with module attribute" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args expected number of times

      #{yellow()}Given:#{reset()}
      [1, @asdf]

      @asdf 2

      #{yellow()}History:#{reset()}
      args: [#{green()}1#{reset()}, 2]
      call: [#{red()}3#{reset()}, 2]
      """

      Utils.push_call(Foo, :bar, 2, [3, 2])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, @asdf], times: 2
        end

      assert error.message == error_msg
    end

    test "one call with unbound variable" do
      error_msg = """
      #{red()}Foo.bar/3 was not called with given args expected number of times

      #{yellow()}Given:#{reset()}
      [1, _asdf, 3]

      #{yellow()}History:#{reset()}
      args: [#{green()}1#{reset()}, _asdf, 3]
      call: [3, #{red()}2#{reset()}, 3]
      """

      Utils.push_call(Foo, :bar, 3, [3, 2, 3])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [1, _asdf, 3], times: 2
        end

      assert error.message == error_msg
    end

    @a 2
    @z 3
    test "one call with multiple pins and module attrs" do
      error_msg = """
      #{red()}Foo.bar/4 was not called with given args expected number of times

      #{yellow()}Given:#{reset()}
      [@a, ^a, @z, ^z]

      @a 2
      @z 3
      a = 4
      z = 5

      #{yellow()}History:#{reset()}
      args: [#{green()}2#{reset()}, #{green()}^a#{reset()}, #{green()}3#{reset()}, #{green()}^z#{reset()}]
      call: [#{red()}1#{reset()}, #{red()}1#{reset()}, #{red()}1#{reset()}, #{red()}1#{reset()}]
      """

      Utils.push_call(Foo, :bar, 4, [1, 1, 1, 1])

      a = 4
      z = 5

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [@a, ^a, @z, ^z], times: 2
        end

      assert error.message == error_msg
    end

    @a 2
    @z 3
    test "one call with multiple pins and module attrs (non alphabetical order of pins and attrs)" do
      error_msg = """
      #{red()}Foo.bar/4 was not called with given args expected number of times

      #{yellow()}Given:#{reset()}
      [^z, @z, ^a, @a]

      @a 2
      @z 3
      a = 4
      z = 5

      #{yellow()}History:#{reset()}
      args: [#{green()}^z#{reset()}, #{green()}3#{reset()}, #{green()}^a#{reset()}, #{green()}2#{reset()}]
      call: [#{red()}1#{reset()}, #{red()}1#{reset()}, #{red()}1#{reset()}, #{red()}1#{reset()}]
      """

      Utils.push_call(Foo, :bar, 4, [1, 1, 1, 1])

      a = 4
      z = 5

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [^z, @z, ^a, @a], times: 2
        end

      assert error.message == error_msg
    end

    test "one call with correct arity, two calls with different arity" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args

      #{yellow()}Given:#{reset()}
      [2, 2]

      #{yellow()}History:#{reset()}
      args: [#{green()}2#{reset()}, #{green()}2#{reset()}]
      call: [#{red()}4#{reset()}, #{red()}4#{reset()}]

      #{yellow()}History (same function name, different arity):#{reset()}
      [1]
      [3, 3, 3]
      """

      Utils.push_call(Foo, :bar, 1, [1])
      Utils.push_call(Foo, :bar, 2, [4, 4])
      Utils.push_call(Foo, :bar, 3, [3, 3, 3])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [2, 2]
        end

      assert error.message == error_msg
    end

    test "two calls with different arity" do
      error_msg = """
      #{red()}Foo.bar/2 was not called with given args

      #{yellow()}Given:#{reset()}
      [2, 2]

      #{yellow()}History:#{reset()}
      (#{light_yellow()}#{underline()}empty - no function calls were registered#{reset()})

      #{yellow()}History (same function name, different arity):#{reset()}
      [1]
      [3, 3, 3]
      """

      Utils.push_call(Foo, :bar, 1, [1])
      Utils.push_call(Foo, :bar, 3, [3, 3, 3])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, args: [2, 2]
        end

      assert error.message == error_msg
    end

    test "very big pattern" do
      error_msg = """
      #{red()}Redix.pipeline/2 was not called with given args

      #{yellow()}Given:#{reset()}
      [
        :redix,
        [
          ["HSET", ^access_token_namespace, ^id, ^access_token],
          ["EXPIRE", ^access_token_namespace, ^id, _],
          ["HSET", ^refresh_token_namespace, ^id, ^refresh_token],
          ["EXPIRE", ^refresh_token_namespace, ^id, _],
          ["HSET", ^session_metadata_namespace, ^id, ^client_ip],
          ["EXPIRE", ^session_metadata_namespace, ^id, _],
          ["SADD", ^active_users_set, ^id]
        ]
      ]

      access_token = "access_abc123"
      access_token_namespace = "access_tokens"
      active_users_set = "active_users"
      client_ip = "192.0.2.1"
      id = "user:123"
      refresh_token = "refresh_def456"
      refresh_token_namespace = "refresh_tokens"
      session_metadata_namespace = "session_meta"

      #{yellow()}History:#{reset()}
      args: [
              :redix,
              [
                ["HSET", ^access_token_namespace, ^id, ^access_token],
                ["EXPIRE", ^access_token_namespace, ^id, _],
                ["HSET", ^refresh_token_namespace, ^id, #{green()}^refresh_token#{reset()}],
                ["EXPIRE", ^refresh_token_namespace, ^id, _],
                ["HSET", ^session_metadata_namespace, ^id, ^client_ip],
                ["EXPIRE", ^session_metadata_namespace, ^id, _],
                ["SADD", ^active_users_set, ^id]
              ]
            ]
      call: [
              :redix,
              [
                ["HSET", "access_tokens", "user:123", "access_abc123"],
                ["EXPIRE", "access_tokens", "user:123", 1000],
                ["HSET", "refresh_tokens", "user:123", "#{red()}access_abc123#{reset()}"],
                ["EXPIRE", "refresh_tokens", "user:123", 1000],
                ["HSET", "session_meta", "user:123", "192.0.2.1"],
                ["EXPIRE", "session_meta", "user:123", 1000],
                ["SADD", "active_users", "user:123"]
              ]
            ]

      args: [
              :redix,
              [
                ["HSET", ^access_token_namespace, ^id, #{green()}^access_token#{reset()}],
                ["EXPIRE", ^access_token_namespace, ^id, _],
                ["HSET", ^refresh_token_namespace, ^id, ^refresh_token],
                ["EXPIRE", ^refresh_token_namespace, ^id, _],
                ["HSET", ^session_metadata_namespace, ^id, ^client_ip],
                ["EXPIRE", ^session_metadata_namespace, ^id, _],
                ["SADD", ^active_users_set, ^id]
              ]
            ]
      call: [
              :redix,
              [
                ["HSET", "access_tokens", "user:123", "#{red()}refresh_def456#{reset()}"],
                ["EXPIRE", "access_tokens", "user:123", 1000],
                ["HSET", "refresh_tokens", "user:123", "refresh_def456"],
                ["EXPIRE", "refresh_tokens", "user:123", 1000],
                ["HSET", "session_meta", "user:123", "192.0.2.1"],
                ["EXPIRE", "session_meta", "user:123", 1000],
                ["SADD", "active_users", "user:123"]
              ]
            ]
      """

      access_token_namespace = "access_tokens"
      refresh_token_namespace = "refresh_tokens"
      session_metadata_namespace = "session_meta"
      active_users_set = "active_users"

      access_token = "access_abc123"
      refresh_token = "refresh_def456"
      client_ip = "192.0.2.1"
      id = "user:123"

      Utils.push_call(Redix, :pipeline, 2, [
        :redix,
        [
          ["HSET", access_token_namespace, id, access_token],
          ["EXPIRE", access_token_namespace, id, 1000],
          ["HSET", refresh_token_namespace, id, access_token],
          ["EXPIRE", refresh_token_namespace, id, 1000],
          ["HSET", session_metadata_namespace, id, client_ip],
          ["EXPIRE", session_metadata_namespace, id, 1000],
          ["SADD", active_users_set, id]
        ]
      ])

      Utils.push_call(Redix, :pipeline, 2, [
        :redix,
        [
          ["HSET", access_token_namespace, id, refresh_token],
          ["EXPIRE", access_token_namespace, id, 1000],
          ["HSET", refresh_token_namespace, id, refresh_token],
          ["EXPIRE", refresh_token_namespace, id, 1000],
          ["HSET", session_metadata_namespace, id, client_ip],
          ["EXPIRE", session_metadata_namespace, id, 1000],
          ["SADD", active_users_set, id]
        ]
      ])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Redix, :pipeline,
            args: [
              :redix,
              [
                ["HSET", ^access_token_namespace, ^id, ^access_token],
                ["EXPIRE", ^access_token_namespace, ^id, _],
                ["HSET", ^refresh_token_namespace, ^id, ^refresh_token],
                ["EXPIRE", ^refresh_token_namespace, ^id, _],
                ["HSET", ^session_metadata_namespace, ^id, ^client_ip],
                ["EXPIRE", ^session_metadata_namespace, ^id, _],
                ["SADD", ^active_users_set, ^id]
              ]
            ]
        end

      assert error.message == error_msg
    end
  end

  describe "print/1 when history is enabled (arity provided)" do
    test "single call, expected 2" do
      error_msg = """
      #{red()}Foo.bar/2 was not called expected number of times

      #{yellow()}History:#{reset()}
      [1, 3]
      """

      Utils.push_call(Foo, :bar, 2, [1, 3])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, arity: 2, times: 2
        end

      assert error.message == error_msg
    end

    test "single call but different arity" do
      error_msg = """
      #{red()}Foo.bar/2 was not called

      #{yellow()}History:#{reset()}
      (#{light_yellow()}#{underline()}empty - no function calls were registered#{reset()})

      #{yellow()}History (same function name, different arity):#{reset()}
      [1, 3, 4]
      """

      Utils.push_call(Foo, :bar, 3, [1, 3, 4])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, arity: 2
        end

      assert error.message == error_msg
    end

    test "two calls, expeted two, but one is different arity" do
      error_msg = """
      #{red()}Foo.bar/2 was not called expected number of times

      #{yellow()}History:#{reset()}
      [1, 3]

      #{yellow()}History (same function name, different arity):#{reset()}
      [1, 3, 4]
      """

      Utils.push_call(Foo, :bar, 2, [1, 3])
      Utils.push_call(Foo, :bar, 3, [1, 3, 4])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, arity: 2, times: 2
        end

      assert error.message == error_msg
    end
  end

  describe "print/1 when history is enabled (no args or arity provided)" do
    test "single call, expected 2" do
      error_msg = """
      #{red()}Foo.bar/? was not called expected number of times

      #{yellow()}History:#{reset()}
      [1, 3]
      """

      Utils.push_call(Foo, :bar, 2, [1, 3])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, times: 2
        end

      assert error.message == error_msg
    end

    test "no calls, expected 2" do
      error_msg = """
      #{red()}Foo.bar/? was not called expected number of times

      #{yellow()}History:#{reset()}
      (#{light_yellow()}#{underline()}empty - no function calls were registered#{reset()})
      """

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! Foo, :bar, times: 2
        end

      assert error.message == error_msg
    end
  end

  describe "Mockery.History output example" do
    @describetag :screenshot

    test "1" do
      Utils.push_call(Foo, :bar, 3, [1, 2, 4])

      assert_called! Foo, :bar, args: [1, 2, 3]
    end

    test "2" do
      Utils.push_call(Foo, :bar, 3, [1, 2, 3])

      assert_called! Foo, :bar, args: [1, 1]
    end

    @mod_attr 2
    test "3" do
      Utils.push_call(Foo, :bar, 2, [1, 2])

      my_variable = 1
      assert_called! Foo, :bar, args: [@mod_attr, ^my_variable], times: 2
    end
  end
end
