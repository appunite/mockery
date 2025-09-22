defmodule Mockery.MacroTest do
  use ExUnit.Case, async: false
  use Mockery.Macro

  describe "__using__/1" do
    defp quoted_to_strings(quoted) do
      quoted
      |> Macro.expand(__ENV__)
      |> Macro.to_string()
      |> String.split("\n")
    end

    test "injects code when mockery is enabled" do
      quoted = quote do: Mockery.Macro.__using__([])

      assert [
               "@compile {:no_warn_undefined, Mockery.Proxy.MacroProxy}",
               "import Mockery.Macro"
             ] = quoted_to_strings(quoted)
    end

    test "injects code when mockery is disabled" do
      Application.put_env(:mockery, :enable, false)
      on_exit(fn -> Application.put_env(:mockery, :enable, true) end)

      quoted = quote do: Mockery.Macro.__using__([])

      assert ["import Mockery.Macro"] =
               quoted_to_strings(quoted)
    end
  end

  describe "__using__/1 :supress_dialyzer_warnings" do
    @describetag :dialyzer

    test "module without `:supress_dialyzer_warnings` produces a Dialyzer warning" do
      id = System.unique_integer([:positive])
      mod_name = "DialyzerIntegration#{id}"
      file_path = "lib/#{Macro.underscore(mod_name)}.ex"

      contents = """
      defmodule #{mod_name} do
        use Mockery.Macro

        # introduce a mockable call so the on_definition hook will consider this function
        def fun(), do: mockable(Enum).count([1, 2, 3])
      end
      """

      File.write!(file_path, contents)

      try do
        assert {_out, 0} =
                 System.cmd("mix", ["compile"],
                   stderr_to_stdout: true,
                   env: [{"MIX_ENV", "test"}]
                 )

        assert {out, 2} =
                 System.cmd("mix", ["dialyzer"],
                   stderr_to_stdout: true,
                   env: [{"MIX_ENV", "test"}]
                 )

        warning_msg =
          "lib/dialyzer_integration#{id}.ex:5:call_to_missing\n" <>
            "Call to missing or private function Mockery.Proxy.MacroProxy.count/1."

        assert out =~ warning_msg
      after
        File.rm_rf!(file_path)
        System.cmd("mix", ["compile"], stderr_to_stdout: true, env: [{"MIX_ENV", "test"}])
      end
    end

    test "module with `supress_dialyzer_warnings: true` doesn't produce a Dialyzer warning" do
      id = System.unique_integer([:positive])
      mod_name = "DialyzerIntegration#{id}"
      file_path = "lib/#{Macro.underscore(mod_name)}.ex"

      contents = """
      defmodule #{mod_name} do
        use Mockery.Macro, supress_dialyzer_warnings: true

        # introduce a mockable call so the on_definition hook will consider this function
        def fun(), do: mockable(Enum).count([1, 2, 3])
      end
      """

      File.write!(file_path, contents)

      try do
        assert {_out, 0} =
                 System.cmd("mix", ["compile"],
                   stderr_to_stdout: true,
                   env: [{"MIX_ENV", "test"}]
                 )

        assert {out, 0} =
                 System.cmd("mix", ["dialyzer"],
                   stderr_to_stdout: true,
                   env: [{"MIX_ENV", "test"}]
                 )

        warning_msg =
          "lib/dialyzer_integration#{id}.ex:5:call_to_missing\n" <>
            "Call to missing or private function Mockery.Proxy.MacroProxy.count/1."

        refute out =~ warning_msg
      after
        File.rm_rf!(file_path)
        System.cmd("mix", ["compile"], stderr_to_stdout: true, env: [{"MIX_ENV", "test"}])
      end
    end

    test "module doesn't produce a Dialyzer warning when `:supress_dialyzer_warnings` is enabled globally" do
      id = System.unique_integer([:positive])
      mod_name = "DialyzerIntegration#{id}"
      file_path = "lib/#{Macro.underscore(mod_name)}.ex"

      contents = """
      Application.put_env(:mockery, Mockery.Macro, supress_dialyzer_warnings: true)

      defmodule #{mod_name} do
        use Mockery.Macro

        # introduce a mockable call so the on_definition hook will consider this function
        def fun(), do: mockable(Enum).count([1, 2, 3])
      end
      """

      File.write!(file_path, contents)

      try do
        assert {_out, 0} =
                 System.cmd("mix", ["compile"],
                   stderr_to_stdout: true,
                   env: [{"MIX_ENV", "test"}]
                 )

        assert {out, 0} =
                 System.cmd("mix", ["dialyzer"],
                   stderr_to_stdout: true,
                   env: [{"MIX_ENV", "test"}]
                 )

        warning_msg =
          "lib/dialyzer_integration#{id}.ex:5:call_to_missing\n" <>
            "Call to missing or private function Mockery.Proxy.MacroProxy.count/1."

        refute out =~ warning_msg
      after
        File.rm_rf!(file_path)
        System.cmd("mix", ["compile"], stderr_to_stdout: true, env: [{"MIX_ENV", "test"}])
      end
    end
  end

  describe "mockable/2" do
    test "dev env (atom erlang mod)" do
      Application.put_env(:mockery, :enable, false)
      on_exit(fn -> Application.put_env(:mockery, :enable, true) end)

      quoted_call = quote do: mockable(:a, env: :dev)
      assert Macro.expand_once(quoted_call, __ENV__) == :a
      refute Process.get(Mockery.MockableModule)

      quoted_call = quote do: mockable(:a, env: :dev, by: X)
      assert Macro.expand_once(quoted_call, __ENV__) == :a
      refute Process.get(Mockery.MockableModule)
    end

    test "config enable: true (atom erlang mod) without global mock" do
      assert mockable(:a) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{:a, nil}]
    end

    test "config enable: true (atom erlang mod) with global mock" do
      assert mockable(:a, by: X) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{:a, X}]
    end

    test "dev env (atom elixir mod)" do
      Application.put_env(:mockery, :enable, nil)
      on_exit(fn -> Application.put_env(:mockery, :enable, true) end)

      quoted_call = quote do: mockable(A, env: :dev)
      assert Macro.expand(quoted_call, __ENV__) == A
      refute Process.get(Mockery.MockableModule)

      quoted_call = quote do: mockable(A, env: :dev, by: X)
      assert Macro.expand(quoted_call, __ENV__) == A
      refute Process.get(Mockery.MockableModule)
    end

    test "config enable: true (atom elixir mod) without global mock" do
      assert mockable(A) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, nil}]
    end

    test "config enable: true (atom elixir mod) with global mock" do
      assert mockable(A, by: X) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, X}]
    end

    import ExUnit.CaptureIO

    test "test env" do
      Application.put_env(:mockery, :enable, nil)
      on_exit(fn -> Application.put_env(:mockery, :enable, true) end)

      quoted_call = quote do: mockable(A)

      {{result, _binding}, io} = with_io(:stderr, fn -> Code.eval_quoted(quoted_call) end)

      assert result == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, nil}]

      assert io =~ "warning:"
      assert io =~ Mockery.Macro.warn()
    end
  end

  describe "defmock/2" do
    defmodule Wrapper do
      use Mockery.Macro

      defmock :mock, A
      defmock :global, A, by: X

      def fun1, do: mock()
      def fun2, do: global()
    end

    test "defmock two-arg macro expands to mockable/1" do
      assert Wrapper.fun1() == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, nil}]
    end

    test "defmock three-arg macro expands to mockable/2" do
      assert Wrapper.fun2() == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, X}]
    end
  end
end
