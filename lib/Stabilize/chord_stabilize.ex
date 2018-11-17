defmodule Chord_Stabilize do
  #defp stabilize(state) do
  #  x = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.successor.name}}, :predecessor)
  #
  #  new_successor =
  #    if x != nil and in_range?(x.hash, state.self.hash, false, state.successor.hash, false) do
  #      :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.self.name}}, {:new_state, :successor, x})
  #      x
  #    else
  #      state.successor
  #    end
  #
  #  :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, new_successor.name}}, {:notify, state.self})
  #
  #  Process.send_after(Registry.lookup(Chord_Protocol.Registry, state.self.name) |> Enum.at(0) |> elem(0), :stabilize, @stabilize_period)
  #end
  #
  #defp notify(state, node) do
  #  if state.predecessor == nil or in_range?(node.hash, state.predecessor.hash, false, state.self.hash, false) do
  #    Map.put(state, :predecessor, node)
  #  else
  #    state
  #  end
  #end
  #
  #defp fix_fingers(state, next) do
  #  <<id_int::@trunc_num>> = state.self.hash
  #  id_int = rem(id_int + trunc(:math.pow(2, next)), trunc(:math.pow(2, @trunc_num)))
  #  id = <<id_int::@trunc_num>>
  #  {successor, _} = get_successor(state, id)
  #  new_finger = List.replace_at(state.finger, next, successor)
  #  :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.self.name}}, {:new_state, :finger, new_finger})
  #
  #  next = if next + 1 >= @trunc_num, do: 0, else: next + 1
  #  Process.send_after(Registry.lookup(Chord_Protocol.Registry, state.self.name) |> Enum.at(0) |> elem(0), {:fix_fingers, next}, @fix_fingers_period)
  #end
end