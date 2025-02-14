%% -*- mode: erlang; erlang-indent-level: 2 -*-
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Filename : 	hipe.hrl (automatically generated by hipe.hrl.src)
%%  Purpose  :  Defines some useful macros for debugging and error
%%              reporting.
%%              
%%  History  :	* 2000-11-03 Erik Johansson (happi@it.uu.se): Created.
%% ====================================================================
%%
%% Defines:
%%  msg/2              - Works like io:format but prepends 
%%                       ?MSGTAG to the message.
%%                       If LOGGING is defined then error_logger is used,
%%			 or rather its substitute in code_server.
%%  untagged_msg/2     - Like msg/2 but without the tag.
%%  WARNING_MSG/2      - Prints a tagged warning.
%%  error_msg/2        - Logs a tagged error.
%%  debug_msg/2        - Prints a tagged msg if DEBUG is defined.
%%  IF_DEBUG(A,B)      - Executes A if DEBUG is defined B otherwise.    
%%  IF_DEBUG(Lvl,A,B)  - Executes A if DEBUG is defined to a value >= Lvl 
%%                       otherwise B is executed.    
%%  EXIT               - Exits with added module and line info.
%%  ASSERT             - Exits if the expresion does not evaluate to true.
%%  VERBOSE_ASSSERT    - A message is printed even when an asertion is true.
%%  TIME_STMNT(Stmnt, String, FreeVar) 
%%                     - Times the statemnet Stmnt if TIMING is on.
%%                       The execution time is bound to FreeVar.
%%                       String is printed after the execution
%%                       followed by the execution time in seconds and
%%                       a newline.
%%
%% Flags:
%%  DEBUG           - Turns on debugging. (Can be defined to a integer
%%                    value to determine the level of debugging)
%%  HIPE_LOGGING    - Turn on logging of messages with erl_logger.
%%  DO_ASSERT       - Turn on assertions.
%%  TIMING          - Turn on timing.
%%  HIPE_INSTRUMENT_COMPILER - Turn on instrumentation of the compiler.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(VERSION_STRING(),"3.19.1").
-define(MSGTAG, "<HiPE (v " ++ ?VERSION_STRING() ++ ")> ").
                                                                                
%%
%% Define the message macros with or without logging,
%% depending on the value of the HIPE_LOGGING flag.
%%

-ifdef(HIPE_LOGGING).
-define(msg(Msg, Args),
	code_server:info_msg(?MSGTAG ++ Msg, Args)).
-define(untagged_msg(Msg, Args),
	code_server:info_msg(Msg, Args)).
-define(untagged_error_msg(Msg, Args),
	code_server:error_msg(Msg, Args)).
-else.
-define(msg(Msg, Args),
	io:format(?MSGTAG ++ Msg, Args)).
-define(untagged_msg(Msg, Args),
	io:format(Msg, Args)).
-define(untagged_error_msg(Msg, Args),
	io:format(Msg, Args)).
-endif.

%%
%% Define error and warning messages.
%%
-define(error_msg(Msg, Args),
	?untagged_error_msg(?MSGTAG ++
			      "Error: [~s:~w]: " ++ Msg,
			    [?MODULE,?LINE|Args])).
-define(WARNING_MSG(Msg, Args),
	?msg("Warning: [~s:~w]: " ++ Msg, [?MODULE,?LINE|Args])).

%%
%% Define the macros that are dependent on the debug flag.
%%

-ifdef(DEBUG).
-define(debug_msg(Msg,Data), ?msg(Msg,Data)).
-define(debug_untagged_msg(Msg,Data), ?untagged_msg(Msg,Data)).
-define(IF_DEBUG(DebugAction,NoDebugAction), DebugAction).
-define(IF_DEBUG_LEVEL(Level,DebugAction,NoDebugAction),
	if (Level =< ?DEBUG) -> DebugAction; true -> NoDebugAction end).
-else.
-define(debug_msg(Msg,Data), no_debug).
-define(debug_untagged_msg(Msg,Data), no_debug).
-define(IF_DEBUG(DebugAction,NoDebugAction), NoDebugAction).
-define(IF_DEBUG_LEVEL(Level,DebugAction,NoDebugAction), NoDebugAction).
-endif.

%%
%% Define the exit macro
%%
-define(EXIT(Reason),
 	?msg("EXITED with reason ~w @~w:~w\n", [Reason,?MODULE,?LINE]),
 	erlang:error({?MODULE,?LINE,Reason})).

%%
%% Assertions.
%%
-ifdef(DO_ASSERT).
-define(VERBOSE_ASSERT(X),
	case X of 
	  true ->
	    io:format("Assertion ok ~w ~w\n",[?MODULE,?LINE]),
	    true;
	  __ASSVAL_R -> 
	    io:format("Assertion failed ~w ~w: ~p\n",
		      [?MODULE,?LINE, __ASSVAL_R]),
	    ?EXIT(assertion_failed)
	end).
-define(ASSERT(X),
	case X of 
	  true -> true;
	  _ -> ?EXIT(assertion_failed)
	end).
-else.
-define(ASSERT(X),true).
-define(VERBOSE_ASSERT(X),true).
-endif.


%% Use this to display info, save stuff and so on.
%% Vars cannot be exported from __Action
-define(when_option(__Opt,__Opts,__Action),
	case proplists:get_bool(__Opt,__Opts) of
	  true -> __Action;
	  false -> ok
	end).

%% Timing macros

-ifdef(TIMING).
-define(TIME_STMNT(STMNT,Msg,Timer),
	Timer = hipe_timing:start_timer(),
	STMNT,
	?untagged_msg(Msg ++ "~.2f s\n",[hipe_timing:stop_timer(Timer)/1000])).
-else.
-define(TIME_STMNT(STMNT,Msg,Timer), STMNT).
-endif.

-define(start_timer(Text), hipe_timing:start(Text, ?MODULE)).
-define(stop_timer(Text), hipe_timing:stop(Text, ?MODULE)).
-define(start_hipe_timer(Timer), hipe_timing:start_hipe_timer(Timer)).
-define(stop_hipe_timer(Timer), hipe_timing:stop_hipe_timer(Timer)).
-define(get_hipe_timer_val(Timer), get(Timer)).
-define(set_hipe_timer_val(Timer, Val), put(Timer, Val)).
-define(option_time(Stmnt, Text, Options),
        begin
	    ?when_option(time, Options, ?start_timer(Text)),
	    fun(R) ->
		    ?when_option(time, Options, ?stop_timer(Text)),
		    R
	    end(Stmnt)
	end).

-define(option_start_time(Text, Options),
	?when_option(time, Options, ?start_timer(Text))).

-define(option_stop_time(Text, Options),
	?when_option(time, Options, ?stop_timer(Text))).

-define(opt_start_timer(Text),
	hipe_timing:start_optional_timer(Text, ?MODULE)).
-define(opt_stop_timer(Text),
	hipe_timing:stop_optional_timer(Text, ?MODULE)).
     
%%
%% Turn on instrumentation of the compiler.
%%
-ifdef(HIPE_INSTRUMENT_COMPILER).

-define(count_pre_ra_instructions(Options, NoInstrs),
	?when_option(count_instrs, Options,
		     put(pre_ra_instrs,
			 get(pre_ra_instrs) + NoInstrs))).
-define(count_post_ra_instructions(Options, NoInstrs),
	?when_option(count_instrs, Options,
		     put(post_ra_instrs,
			 get(post_ra_instrs) + NoInstrs))).

-define(start_time_regalloc(Options),
	?when_option(timeregalloc, Options, 
		     put(regalloctime1, erlang:statistics(runtime)))).
-define(stop_time_regalloc(Options),
	?when_option(timeregalloc, Options, 
		     put(regalloctime,
			 get(regalloctime) + 
			 (element(1,erlang:statistics(runtime))
			  -element(1,get(regalloctime1)))))).
-define(start_time_caller_saves(Options),
	?when_option(timeregalloc, Options, 
		     put(callersavetime1,erlang:statistics(runtime)))).
-define(stop_time_caller_saves(Options),
	?when_option(timeregalloc, Options, 
		     put(callersavetime,
			 get(callersavetime) + 
			 (element(1,erlang:statistics(runtime))
			  -element(1,get(callersavetime1)))))).

-define(count_pre_ra_temps(Options, NoTemps),
	?when_option(count_temps, Options,
		     put(pre_ra_temps,
			 get(pre_ra_temps) + NoTemps))).
-define(count_post_ra_temps(Options, NoTemps),
	?when_option(count_temps, Options,
		     put(post_ra_temps,
			 get(post_ra_temps) + NoTemps))).

-define(inc_counter(Counter, Val),
	case get(Counter) of
	  undefined -> true;
	  _ -> put(Counter, Val + get(Counter))
	end).

-define(cons_counter(Counter, Val),
	case get(Counter) of
	  undefined -> true;
	  _ -> put(Counter, [Val|get(Counter)])
	end).

-define(update_counter(Counter, Val, Op),
	case get(Counter) of
	  undefined -> true;
	  _ -> put(Counter, get(Counter) Op Val)
	end).

-define(start_ra_instrumentation(Options, NoInstrs, NoTemps),
	begin
	  ?count_pre_ra_instructions(Options, NoInstrs),
	  ?count_pre_ra_temps(Options, NoTemps),
	  case get(counter_mem_temps) of
	    undefined -> true;
	    _ -> put(counter_mfa_mem_temps,[])
	  end,
	  ?start_time_regalloc(Options)
	end).
-define(stop_ra_instrumentation(Options, NoInstrs, NoTemps),
	begin
	  ?stop_time_regalloc(Options),
	  ?count_post_ra_instructions(Options, NoInstrs),
	  ?cons_counter(counter_mem_temps, get(counter_mfa_mem_temps)),
	  ?cons_counter(ra_all_iterations_counter, get(ra_iteration_counter)),
	  put(ra_iteration_counter, 0),
	  ?count_post_ra_temps(Options, NoTemps)
	end).

-define(add_spills(Options, NoSpills),
	?when_option(count_spills, Options, 
		     put(spilledtemps, get(spilledtemps) + NoSpills))).

-define(optional_start_timer(Timer, Options),
	case lists:member(Timer, proplists:get_value(timers, Options++[{timers,[]}])) of
	  true -> ?start_hipe_timer(Timer);
	  false -> true
	end).
-define(optional_stop_timer(Timer, Options),
	case lists:member(Timer, proplists:get_value(timers, Options++[{timers,[]}])) of
	  true -> ?stop_hipe_timer(Timer);
	  false -> true
	end).
	
-else.  %% HIPE_INSTRUMENT_COMPILER

-define(count_pre_ra_instructions(Options, NoInstrs), no_instrumentation).
-define(count_post_ra_instructions(Options, NoInstrs),no_instrumentation).
-define(start_time_regalloc(Options), no_instrumentation).
-define(stop_time_regalloc(Options), no_instrumentation).
-define(start_time_caller_saves(Options), no_instrumentation).
-define(stop_time_caller_saves(Options), no_instrumentation).
-define(count_pre_ra_temps(Options, NoTemps), no_instrumentation).
-define(count_post_ra_temps(Options, NoTemps), no_instrumentation).
-define(start_ra_instrumentation(Options, NoInstrs, NoTemps),no_instrumentation).
-define(stop_ra_instrumentation(Options, NoInstrs, NoTemps),no_instrumentation).
-define(add_spills(Options, NoSpills), no_instrumentation).
-define(optional_start_timer(Options, Timer), no_instrumentation).
-define(optional_stop_timer(Options, Timer), no_instrumentation).
-define(inc_counter(Counter, Val), no_instrumentation).
-define(update_counter(Counter, Val, Op), no_instrumentation).
-define(cons_counter(Counter, Val), no_instrumentation).

-endif. %% HIPE_INSTRUMENT_COMPILER

%%----------------------------------------------------------------------------
%% Records defined in the hipe module used in other parts of the compiler
%%----------------------------------------------------------------------------

-type mpid() :: 'none' | pid().
-record(comp_servers, {pp_server :: mpid(), range :: mpid(), type :: mpid()}).

%%----------------------------------------------------------------------------
%% Basic types of the 'hipe' application used in other parts of the system
%%----------------------------------------------------------------------------

-type comp_option()  :: atom() | {atom(), atom()}.
-type comp_options() :: [comp_option()].

-type hipe_architecture() ::
		'amd64' | 'arm' | 'powerpc' | 'ppc64' | 'ultrasparc' | 'x86'.

-type hipe_map()       :: [{non_neg_integer(),
	                    'unknown' | {'reg' | 'fp_reg' | 'spill',
	                                 non_neg_integer()}}].
-type hipe_temp_map()  :: tuple().
-type hipe_spill_map() :: [{non_neg_integer(), {'spill', non_neg_integer()}}].
