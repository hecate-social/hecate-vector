%%% @doc Top-level supervisor.
%%%
%%% Owns the dynamic per-index supervisor.
-module(hecate_vector_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-spec start_link() -> {ok, pid()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 10
    },
    Children = [
        #{
            id => hecate_vector_index_sup,
            start => {hecate_vector_index_sup, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => supervisor,
            modules => [hecate_vector_index_sup]
        }
    ],
    {ok, {SupFlags, Children}}.
