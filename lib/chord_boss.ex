#---
# Title        : Assignment - 3,
# Subject      : Distributed And Operating Systems Principles
# Team Members : Priyam Saikia, Noopur R Kalawatia
# File name    : chord_boss.exs
#---

defmodule Chord_Protocol.Chord_Boss do
  use GenServer

  #------------------------------------- Start Link Function ------------------------------
  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: Chord_Protocol.Chord_Boss)
  end

  #------------------------------------- Init Function ------------------------------ 
  def init(arg) do
    peers_checklist = Enum.reduce(1..arg.numNodes, %{}, fn(x, acc) -> Map.put(acc, "node_#{x}", false) end)
    state = Map.merge(arg, %{
      added_peers: %{},
      added_peers_count: 0,
      peers_checklist: peers_checklist,
      peersDone: 0,
      join_status: 0
    })
    {:ok, state}
  end
  #------------------------------------- Handle Call Functions ------------------------------
  def handle_call(:get_random_entry_node, _from, state) do
    if state.added_peers_count == 0 do
      {:reply, nil, state}
    else
      index = :rand.uniform(state.added_peers_count)
      random_node = state.added_peers[index]
      {:reply, random_node, state}
    end
  end

  def handle_call({:node_joined, node}, _from, state) do
    new_added_peers = Map.put(state.added_peers, state.added_peers_count + 1, node)
    curr_state = Map.merge(state, %{added_peers: new_added_peers, added_peers_count: state.added_peers_count + 1})
    if curr_state.added_peers_count == curr_state.numNodes do
      Enum.each(Map.values(curr_state.added_peers), fn(x) -> GenServer.cast({:via, Registry, {Chord_Protocol.Registry, x.name}}, :all_node_joined) end)
      IO.puts "Chord Protocol begins..."
    end
    {:reply, :ok, curr_state}
  end

  def handle_call({:node_finish, node, average_hop}, from, state) do
    GenServer.reply(from, :ok)

    if state.peers_checklist[node] == false do
      new_peers_checklist = Map.put(state.peers_checklist, node, average_hop)
      curr_state = Map.merge(state, %{peers_checklist: new_peers_checklist, peersDone: state.peersDone + 1})
      if curr_state.peersDone == curr_state.numNodes do
        Enum.each(1..curr_state.numNodes, fn(x) -> GenServer.cast({:via, Registry, {Chord_Protocol.Registry, "node_#{x}"}}, :terminate) end)
        :timer.sleep(2000)
        {:stop, :normal, curr_state}
      else
        {:noreply, curr_state}
      end
    else
      {:noreply, state}
    end
  end
  #------------------------------------- Terminate Function ------------------------------
  def terminate(reason, state) do
    if reason == :normal do
      avg_hop = Enum.reduce(Map.values(state.peers_checklist), 0, fn(x, acc) -> x + acc end) / state.numNodes
      IO.puts "Average hops: #{avg_hop}"
    else
      IO.inspect(reason)
    end
    send(state.daemon, :done)
  end

end
