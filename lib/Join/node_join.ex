#---
# Title        : Assignment - 3,
# Subject      : Distributed And Operating Systems Principles
# Team Members : Priyam Saikia, Noopur R Kalawatia
# File name    : node_join.exs
#---

defmodule Chord_Protocol.Node_Join do
  #------------------------------------- Peer listing Function ------------------------------
  defmodule Peer do
    defstruct name: nil, hash: nil
  end

  @hash_fun :sha
  @hash_num 160
  @trunc_num 40
  @stabilize_period 50
  @check_predecessor_period 50
  @fix_fingers_period 20

  use GenServer

  #------------------------------------- Start Link Function ------------------------------

  def start_link(arg) do
    name = {:via, Registry, {Chord_Protocol.Registry, "node_#{Enum.at(arg, 1)}"}}
    GenServer.start_link(__MODULE__, arg |> Enum.at(0) |> Map.put(:id, Enum.at(arg, 1)), name: name)
  end

  #------------------------------------- Init Function ------------------------------

  def init(arg) do
    GenServer.cast(self(), :start)
    x_bits = get_hash("node_#{arg.id}")
    failNode = if arg.fail_mode and Enum.random(1..100) <= arg.failNodes, do: true, else: false
    finger = Enum.reduce(1..@trunc_num, [], fn(_, acc) -> [nil|acc] end)
    state = Map.merge(arg, %{
      self: %Peer{name: "node_#{arg.id}", hash: x_bits},
      predecessor: nil,
      successor: nil,
      finger: finger,
      failNode: failNode,
      total_hops: 0,
      msg_delivered: 0,
      alive: not failNode
    })
    {:ok, state}
  end
  #------------------------------------- Handle Cast Functions ------------------------------
  def handle_cast(:start, state) do
    entry_node = GenServer.call(Chord_Protocol.Chord_Boss, :get_random_entry_node)
    new_state = if entry_node == nil, do: create(state), else: join(state, entry_node)
    :ok = GenServer.call(Chord_Protocol.Chord_Boss, {:node_joined, new_state.self})
    {:noreply, new_state}
  end

  def handle_cast(:all_node_joined, state) do
    Process.send_after(self(), :stabilize, @stabilize_period)
    Process.send_after(self(), :check_predecessor, @check_predecessor_period)
    Process.send_after(self(), {:fix_fingers, 0}, @fix_fingers_period)
    Process.send_after(self(), :message, 5000)
    {:noreply, state}
  end

  def handle_cast({:get_successor, id, callee, hops}, state) do
    get_successor(state, id, callee, hops + 1)
    {:noreply, state}
  end

  def handle_cast(:terminate, state) do
    new_state = Map.put(state, :alive, false)
    {:stop, :normal, new_state}
  end
  #------------------------------------- Handle Call Functions ------------------------------
  def handle_call({:new_state, key, value}, _from, state), do: {:reply, :ok, Map.put(state, key, value)}

  def handle_call({:get_successor, id}, from, state) do
    get_successor(state, id, from, 1)
    {:noreply, state}
  end

  def handle_call(:predecessor, _from, state), do: {:reply, state.predecessor, state}

  def handle_call({:notify, node}, _from, state), do: {:reply, :ok, notify(state, node)}

  def handle_info(:stabilize, state) do
    if state.alive and not state.failNode, do: spawn_link(fn() -> stabilize(state) end)
    {:noreply, state}
  end

  #------------------------------------- Handle Info Functions ------------------------------
  def handle_info(:check_predecessor, state) do
    if state.alive and not state.failNode, do: spawn_link(fn() -> check_predecessor(state) end)
    {:noreply, state}
  end

  def handle_info({:fix_fingers, next}, state) do
    if state.alive and not state.failNode, do: spawn_link(fn() -> fix_fingers(state, next) end)
    {:noreply, state}
  end

  def handle_info(:message, state) do
    cond do
      state.msg_delivered == state.numRequests ->
        average_hop = state.total_hops / state.numRequests
        :ok = GenServer.call(Chord_Protocol.Chord_Boss, {:node_finish, state.self.name, average_hop})
      not state.failNode ->
        message = Enum.reduce(1..10, "", fn(_, acc) -> acc <> <<Enum.random(0..255)>> end)
        message_hash = get_hash(message)
        spawn_link(fn() -> send_message(state, message_hash) end)
        Process.send_after(self(), :message, 1000)
      state.failNode ->
        average_hop = 0
        :ok = GenServer.call(Chord_Protocol.Chord_Boss, {:node_finish, state.self.name, average_hop})
    end
    {:noreply, state}
  end
  #------------------------------------- Terminate Function ------------------------------
  def terminate(reason, _state) do
    if reason != :normal, do: IO.inspect(reason)
    :timer.sleep(1000)
  end
  
  #------------------------------------- Chord Specific Functions ------------------------------
  defp get_successor(state, id) do
    if in_range?(id, state.self.hash, false, state.successor.hash, true) do
      {state.successor, 0}
    else
      cpn = nearest_prev_node(state, id, @trunc_num - 1)
      if cpn == state.self do
        {state.self, 0} 
      else
        GenServer.call({:via, Registry, {Chord_Protocol.Registry, cpn.name}}, {:get_successor, id})
      end
    end
  end

  defp get_successor(state, id, callee, hops) do
    if in_range?(id, state.self.hash, false, state.successor.hash, true) do
      GenServer.reply(callee, {state.successor, hops})
    else
      cpn = nearest_prev_node(state, id, @trunc_num - 1)
      if cpn == state.self do
        GenServer.reply(callee, {state.self, hops}) 
      else
        GenServer.cast({:via, Registry, {Chord_Protocol.Registry, cpn.name}}, {:get_successor, id, callee, hops})
      end
    end
  end

  defp nearest_prev_node(state, _id, i) when i < 0, do: state.self

  defp nearest_prev_node(state, id, i) do
    if Enum.at(state.finger, i) == nil do
      state.self
    else
      if in_range?(Enum.at(state.finger, i).hash, state.self.hash, false, id, false), do: Enum.at(state.finger, i), else: nearest_prev_node(state, id, i - 1)
    end
  end

  defp create(state) do
    Map.merge(state, %{predecessor: nil, successor: state.self})
  end

  defp join(state, entry_node) do
    {successor, _} = GenServer.call({:via, Registry, {Chord_Protocol.Registry, entry_node.name}}, {:get_successor, state.self.hash})
    Map.merge(state, %{predecessor: nil, successor: successor})
  end

  defp stabilize(state) do
    x = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.successor.name}}, :predecessor)

    new_successor =
      if x != nil and in_range?(x.hash, state.self.hash, false, state.successor.hash, false) do
        :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.self.name}}, {:new_state, :successor, x})
        x
      else
        state.successor
      end

    :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, new_successor.name}}, {:notify, state.self})

    Process.send_after(Registry.lookup(Chord_Protocol.Registry, state.self.name) |> Enum.at(0) |> elem(0), :stabilize, @stabilize_period)
  end

  defp notify(state, node) do
    if state.predecessor == nil or in_range?(node.hash, state.predecessor.hash, false, state.self.hash, false) do
      Map.put(state, :predecessor, node)
    else
      state
    end
  end

  defp fix_fingers(state, next) do
    <<id_int::@trunc_num>> = state.self.hash
    id_int = rem(id_int + trunc(:math.pow(2, next)), trunc(:math.pow(2, @trunc_num)))
    id = <<id_int::@trunc_num>>
    {successor, _} = get_successor(state, id)
    new_finger = List.replace_at(state.finger, next, successor)
    :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.self.name}}, {:new_state, :finger, new_finger})

    next = if next + 1 >= @trunc_num, do: 0, else: next + 1
    Process.send_after(Registry.lookup(Chord_Protocol.Registry, state.self.name) |> Enum.at(0) |> elem(0), {:fix_fingers, next}, @fix_fingers_period)
  end

  defp check_predecessor(state) do
    if state.predecessor != nil and GenServer.whereis({:via, Registry, {Chord_Protocol.Registry, state.predecessor.name}}) == nil do
      :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.self.name}}, {:new_state, :predecessor, nil})
    end
    Process.send_after(Registry.lookup(Chord_Protocol.Registry, state.self.name) |> Enum.at(0) |> elem(0), :check_predecessor, @check_predecessor_period)
  end

  defp send_message(state, message_hash) do
    {_result, hops} = get_successor(state, message_hash)
    :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.self.name}}, {:new_state, :total_hops, state.total_hops + hops})
    :ok = GenServer.call({:via, Registry, {Chord_Protocol.Registry, state.self.name}}, {:new_state, :msg_delivered, state.msg_delivered + 1})
  end

  defp in_range?(target, left, leftPlus, right, rightPlus) do
    cond do
      left < right ->
        if target >= left and target <= right do
          if (target == left and not leftPlus) or (target == right and not rightPlus), do: false, else: true
        else
          false
        end
      left == right ->
        if target == left and (not leftPlus or not rightPlus), do: false, else: true
      left > right ->
        if target > right and target < left do
          false
        else
          if (target == left and not leftPlus) or (target == right and not rightPlus), do: false, else: true
        end
    end
  end

  defp get_hash(input) do
    remain_digest = @hash_num - @trunc_num
    <<_::size(remain_digest), x::@trunc_num>> = :crypto.hash(@hash_fun, input)
    <<x::@trunc_num>>
  end
end
