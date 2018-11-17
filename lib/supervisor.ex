#---
# Title        : Assignment - 3,
# Subject      : Distributed And Operating Systems Principles
# Team Members : Priyam Saikia, Noopur R Kalawatia
# File name    : supervisor.exs
#---

defmodule Chord_Protocol.Supervisor do
  use Supervisor
  #----------------------------------Start Link-------------------------------------------------
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end
  #---------------------------------------Init Function--------------------------------------------
  def init(args) do
    if Enum.at(System.argv(), 1) == nil do
      IO.puts "Please enter input in the pattern:     mix run entrypoint.exs <numNodes> <numRequests>"
      {:invalid_argv}
    else
      registry = {Registry, keys: :unique, name: Chord_Protocol.Registry, partitions: System.schedulers_online()}

      numNodes = System.argv() |> Enum.at(0) |> String.to_integer()
      numRequests = System.argv() |> Enum.at(1) |> String.to_integer()

      common = %{numRequests: numRequests, fail_mode: false}

      main_actor = Supervisor.child_spec({Chord_Protocol.Chord_Boss, Map.merge(common, %{numNodes: numNodes, daemon: args})}, restart: :transient)

      peers = Enum.reduce(numNodes..1, [],
        fn(x, acc) -> [Supervisor.child_spec({Chord_Protocol.Node_Join, [common, x]}, id: {Chord_Protocol.Node_Join, x}, restart: :temporary) | acc] end)

      peerlist = [registry | [main_actor | peers]]

      Supervisor.init(peerlist, strategy: :one_for_one)
    end
  end
end
