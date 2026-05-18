%%% @doc hecate_vector OTP application entry point.
-module(hecate_vector_app).
-behaviour(application).

-export([start/2, stop/1]).

-spec start(application:start_type(), term()) -> {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    hecate_vector_sup:start_link().

-spec stop(term()) -> ok.
stop(_State) ->
    ok.
