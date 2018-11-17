#---
# Title        : Assignment - 3,
# Subject      : Distributed And Operating Systems Principles
# Team Members : Priyam Saikia, Noopur R Kalawatia
# File name    : chord_protocol.exs
#---

# This module starts the start_link of the chord protocol process. It calls self and 
# gets the arguments
defmodule Chord_Protocol do
#------------------------------------- Main Function ------------------------------
  def main do
    {:ok, _} = Chord_Protocol.Supervisor.start_link(self())
    receive do
      :done -> IO.write("Completed Chord Protocol")
    end
    System.halt(0)
  end
end

#-----------------------------------------------------------------------------------