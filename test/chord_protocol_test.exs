defmodule Chord_ProtocolTest do
  use ExUnit.Case
  doctest Chord_Protocol

  test "greets the world" do
    assert Chord_Protocol.hello() == :world
  end
end
