-module(lp496_a4).
-export([pick/2, send_all/2, atomforks/2, constrained_integer/2, get_upper/1, process_constraints/2, set_up/3, report/1]).
% -complie(export_all).

% Question 1
% Arguments: 
%   Association List of pairs {X, Y}
%   Key Value X
pick([], _) -> error;
pick([{V, W} | _], V) -> W;
pick([{_, _} | XS], V) -> pick(XS, V).

% Question 2
% Arguments: 
%   List of process identifiers
%   Erlang value M
send_all([], _) -> ok;
send_all([P | PS], M) -> 
    P ! M,
    send_all(PS, M).

% Question 3
% Arguments:
%   List of atoms
%   Nullary Function
atomforks([], _) -> [];
atomforks([A | AS], F) -> 
    [{A, spawn(fun() -> F() end)} | atomforks(AS, F)].

% Question 4
% Arguements:
%   Upper bound UB
%   List of lower bounds
constrained_integer(UB, LBS) ->
    receive 
        {upperbound, Pid} ->
            Upper = UB,
            Lower = LBS,
            Pid ! {upperbound, UB, self()};
        {impose, UB2} -> 
            Lower = LBS, 
            case UB < (UB2+1) of 
                true -> 
                    Upper = UB;
                false -> 
                    send_all(LBS, {impose, UB2-1}),
                    Upper = UB2
            end;
        {lowerbound, Pid} -> 
            Upper = UB,
            Pid ! {impose, Upper-1}, % Unsure if this is needed
            Lower = [Pid | LBS]
    end,
    constrained_integer(Upper, Lower).
    
% Question 5
% Arguments:
%   Constrainted integer (process id)
get_upper(CInt) ->
    CInt ! {upperbound, self()},
    receive 
        {upperbound, UB, CInt} -> UB
    end.

% Question 6
% Arguments:
%   List of constraints {P, Q}
%   Association List (pairing atoms with proccess ids of CIs)
process_constraints([],_) -> ok;
process_constraints([{P, Q} | XS], PS) ->
    pick(PS, Q) ! {lowerbound, pick(PS, P)},
    process_constraints(XS, PS).

% Question 7
% Arguments:
%   A list of atoms
%   A number N that serves as a global upper bound for all atoms
%   A list of constraints
set_up([], _, _) -> [];
set_up([A | AS], N, CS) -> 
    Dict = [{A, spawn(?MODULE, constrained_integer, [N, []])} | set_up(AS, N, [])],
    process_constraints(CS, Dict),
    timer:sleep(100),
    Dict.

% Question 8 
% Arguments:
%   Association list of atoms and constrianed ints
report([]) -> [];
report([{A, CInt} | AS]) -> 
    [{A, get_upper(CInt)} | report(AS)].
    
