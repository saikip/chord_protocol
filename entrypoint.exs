#---
# Title        : Assignment - 3,
# Subject      : Distributed And Operating Systems Principles
# Team Members : Priyam Saikia, Noopur R Kalawatia
# File name    : entrypoint.exs
#---

# This routine is used to feed arguments to our chord protocol routine 
# through commandline

# Verify number of arguments
if (length(System.argv) != 2) do
  IO.puts("Please enter input in the pattern:     mix run entrypoint.exs <numNodes> <numRequests>")
  System.halt(0)
end

# Populate corresponding variables
[arg1,arg2] = Enum.map(System.argv,fn x -> String.to_integer(x) end)
#[arg1,arg2] = System.argv()
#arg1 = String.to_integer(arg1)

# Verify number of Nodes
if (arg1 <= 1) do
  IO.puts("Please enter more than 1 numNodes")
  System.halt(0)
end
# Verify number of Requests
if (arg2 <= 1) do
  IO.puts("Please enter more than 1 numRequests")
  System.halt(0)
end

# Call Chord Protocol main function
Chord_Protocol.main() 
