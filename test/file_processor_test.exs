defmodule FileProcessorTest do
  use ExUnit.Case
  doctest FileProcessor

  test "greets the world" do
    assert FileProcessor.hello() == :world
  end
end
