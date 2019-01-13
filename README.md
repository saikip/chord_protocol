## **CHORD PROTOCOL - COP5615: Fall 2018**

## **TEAM INFO**
Priyam Saikia (UFID **** ****)

## **PROBLEM**
Design chord protocol using genserver/Actor model in Elixir to implement the network join and routing as 
described in the Chord MIT paper and encode the simple application that associates a key with a string.

## **INSTALLATION AND RUN** 

Elixir Mix project is required to be installed. 
Files of importance in the zipped folder (in order of call):

*entrypoint.exs*     -> Commandline entry module

*chord_protocol.ex*  -> Main Module

*supervisor.ex*     -> Supervisor Module

*chord_boss.ex*      -> Worker Module

*Node_join.ex*       -> Sub-Module for join and stabilize

To run a test case, do:

1. Unzip contents to your desired elixir project folder.
2. Open cmd window from this project location (use $cd <location> to change location)
3. Type "mix run entrypoint.exs <numNodes> <numRequests>" in commandline without quotes. 
4. The run terminates when all the peers perform given number of requests (details in report). 
5. The result provides the average number of hops for the message to be delivered

Example:

	C:\Users\PSaikia\Documents\Elixir\kv\chord_protocol>mix run entrypoint.exs 1000 10
	
	Chord Protocol begins...
	
	Average hops: 3.2189000000000005
	
	Completed Chord Protocol
   
## **WHAT IS WORKING**

We have implemented the chord protocol node join and routing mechanism as mentioned in the MIT paper. 
Each peer is being added to the overlay network. After one peer is joined, next peer can join them to form a DHT.
Once all the peers are joined, the message delivery starts. We pass one request/second and this continues until number of requests for each node is equal to the user-entered numRequests.
Functions mentioned in the paper such as finding successor, finding predecessor, fixing fingers, finding closest preceding peer, creating, joining, notify, and stabilizing has been implemented.

## **LARGEST NETWORK**
    
**Largest network tested:**
	
	Largest Number of Nodes tested: 5000
	
	Largest Number of Requests: 100
	
Sample:
	
	C:\Users\PSaikia\Documents\Elixir\kv\chord_protocol>mix run entrypoint.exs 5000 100
	
	Chord Protocol begins...
	
	Average hops: 4.097342000000015
	
	Completed Chord Protocol
