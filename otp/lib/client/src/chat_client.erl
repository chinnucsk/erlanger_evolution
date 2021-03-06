%%%-------------------------------------------------------------------
%%% File    : chat_client.erl
%%% Author  : Tristan Sloughter <>
%%% Description : 
%%%
%%% Created : 13 May 2010 by Tristan Sloughter <>
%%%-------------------------------------------------------------------
-module(chat_client).

-behaviour(gen_server).

%% API
-export([start_link/2, reconnect/1, logout/0, broadcast/1, send_message/2, message/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {server, username, is_connected=false}).

-define(SERVER, ?MODULE).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link(Server, UserName) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [Server, UserName], []).

%%====================================================================
%% gen_server callbacks
%%====================================================================
reconnect(UserName) ->
    gen_server:call(?SERVER, {reconnect, UserName}).

logout() ->
    gen_server:call(?SERVER, logout).

broadcast(Message) ->
    gen_server:cast(?SERVER, {broadcast, Message}).

send_message(To, Message) ->
    gen_server:cast(?SERVER, {message, To, Message}).

message(Pid, From, Message) ->
    gen_server:cast(Pid, {received, From, Message}).

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([Server, UserName]) ->
    chat_server:login(Server, self(), UserName),   
    {ok, #state{server=Server, username=UserName, is_connected=true}}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({reconnect, UserName}, _From, State) ->
    Server = State#state.server,
    Reply = chat_server:login(Server, self(), UserName),
    {reply, Reply, State#state{username=UserName, is_connected=true}};
handle_call(logout, _From, State) ->
    Server = State#state.server,
    Reply = chat_server:logout(Server, State#state.username),
    {reply, Reply, State#state{is_connected=false}}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%-------------------------------------------------------------------
handle_cast({received, From, Message}, State) ->
    io:format("~s : ~s~n", [From, Message]),
    {noreply, State};
handle_cast({message, To, Message}, State) ->
    UserName = State#state.username,
    Server = State#state.server,
    chat_server:message(Server, To, UserName, Message),
    {noreply, State};
handle_cast({broadcast, Message}, State) ->
    UserName = State#state.username,
    Server = State#state.server,
    chat_server:broadcast(Server, UserName, Message),
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
