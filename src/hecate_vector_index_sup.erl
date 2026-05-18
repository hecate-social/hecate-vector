%%% @doc Dynamic supervisor for per-index gen_servers.
-module(hecate_vector_index_sup).
-behaviour(supervisor).

-export([start_link/0, start_index/2]).
-export([init/1]).

-spec start_link() -> {ok, pid()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec start_index(atom(), map()) -> {ok, pid()} | {error, term()}.
start_index(Name, Opts) ->
    supervisor:start_child(?MODULE, [Name, Opts]).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{
        strategy => simple_one_for_one,
        intensity => 10,
        period => 10
    },
    Children = [
        #{
            id => hecate_vector_index,
            start => {hecate_vector_index, start_link, []},
            restart => transient,
            shutdown => 5000,
            type => worker,
            modules => [hecate_vector_index]
        }
    ],
    {ok, {SupFlags, Children}}.
