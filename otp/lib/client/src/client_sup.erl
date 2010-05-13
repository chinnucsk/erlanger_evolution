%%%----------------------------------------------------------------
%%% @author  Tristan Sloughter <kungfooguru@gmail.com>
%%% @doc
%%% @end
%%% @copyright 2010 Tristan Sloughter
%%%----------------------------------------------------------------
-module(client_sup).

-behaviour(supervisor).

%% API
-export([start_link/0, login/2]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

login(Server, UserName) ->
    Restart = permanent,
    Shutdown = 2000,
    Type = worker,

    AChild = {chat_server, {chat_client, start_link, [Server, UserName]},
              Restart, Shutdown, Type, [chat_server]},

    supervisor:start_child(?SERVER, AChild).

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @spec init(Args) -> {ok, {SupFlags, [ChildSpec]}} |
%%                     ignore |
%%                     {error, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    {ok, {SupFlags, []}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


