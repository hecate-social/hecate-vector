%%% @doc Smoke tests for hecate_vector.
%%%
%%% These exercise the NIF round-trip end to end: build a tiny index,
%%% search it, expect the planted nearest neighbour first.
-module(hecate_vector_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([open_and_search/1, dim_mismatch/1, top_k_truncates/1]).

all() ->
    [open_and_search, dim_mismatch, top_k_truncates].

init_per_suite(Config) ->
    {ok, _} = application:ensure_all_started(hecate_vector),
    Config.

end_per_suite(_Config) ->
    application:stop(hecate_vector),
    ok.

open_and_search(_Config) ->
    {ok, Idx} = hecate_vector:open(test_open_and_search, #{dim => 3, capacity => 16}),
    ok = hecate_vector:add(Idx, <<"a">>, [1.0, 0.0, 0.0]),
    ok = hecate_vector:add(Idx, <<"b">>, [0.0, 1.0, 0.0]),
    ok = hecate_vector:add(Idx, <<"c">>, [0.9, 0.1, 0.0]),
    {ok, Hits} = hecate_vector:search(Idx, [1.0, 0.0, 0.0], 2),
    ?assertMatch([{<<"a">>, _}, {<<"c">>, _} | _], Hits),
    ok = hecate_vector:close(Idx).

dim_mismatch(_Config) ->
    {ok, Idx} = hecate_vector:open(test_dim_mismatch, #{dim => 3}),
    ?assertMatch({error, dim_mismatch}, hecate_vector:add(Idx, <<"x">>, [1.0, 2.0])),
    ok = hecate_vector:close(Idx).

top_k_truncates(_Config) ->
    {ok, Idx} = hecate_vector:open(test_top_k, #{dim => 2}),
    [ok = hecate_vector:add(Idx, integer_to_binary(N), [float(N), 0.0]) || N <- lists:seq(1, 20)],
    {ok, Hits} = hecate_vector:search(Idx, [1.0, 0.0], 5),
    ?assertEqual(5, length(Hits)),
    ok = hecate_vector:close(Idx).
