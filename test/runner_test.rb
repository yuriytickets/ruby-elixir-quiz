# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/runner"

class RunnerTest < Minitest::Test
  RUBY_TESTS = <<~RUBY
    require "minitest/autorun"
    class AddTest < Minitest::Test
      def test_add = assert_equal 3, add(1, 2)
    end
  RUBY

  ELIXIR_TESTS = <<~ELIXIR
    ExUnit.start()
    defmodule AddTest do
      use ExUnit.Case
      test "add", do: assert Solution.add(1, 2) == 3
    end
  ELIXIR

  def test_ruby_pass
    res = Runner.run("ruby", "def add(a, b) = a + b", RUBY_TESTS)
    assert res.ok, res.output
    assert_includes res.output, "1 runs, 1 assertions"
  end

  def test_ruby_fail_shows_output
    res = Runner.run("ruby", "def add(a, b) = a - b", RUBY_TESTS)
    refute res.ok
    assert_includes res.output, "Expected: 3"
  end

  def test_ruby_syntax_error
    refute Runner.run("ruby", "def add(a, b", RUBY_TESTS).ok
  end

  def test_timeout
    old = Runner::TIMEOUT
    Runner.send(:remove_const, :TIMEOUT)
    Runner.const_set(:TIMEOUT, 1)
    res = Runner.run("ruby", "def add(a, b) = loop {}", RUBY_TESTS)
    refute res.ok
    assert_includes res.output, "Timed out"
  ensure
    Runner.send(:remove_const, :TIMEOUT)
    Runner.const_set(:TIMEOUT, old)
  end

  def test_elixir_pass_and_fail
    skip "elixir not installed" unless Runner.available?("elixir")
    assert Runner.run("elixir", "defmodule Solution do\n  def add(a, b), do: a + b\nend", ELIXIR_TESTS).ok
    res = Runner.run("elixir", "defmodule Solution do\n  def add(a, b), do: a - b\nend", ELIXIR_TESTS)
    refute res.ok
    assert_includes res.output, "1 failure"
  end

  def test_unsupported_language
    refute Runner.run("cobol", "", "").ok
  end
end
