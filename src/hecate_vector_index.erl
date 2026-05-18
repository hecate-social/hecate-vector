%%% @doc gen_server wrapping a single open ANN index.
%%%
%%% Holds the NIF resource handle and the persistence path. Serialises
%%% mutating calls (add, save). Reads (search) call into the NIF
%%% directly under the BEAM scheduler — the Rust side must use dirty
%%% schedulers if a single search becomes long-running.
-module(hecate_vector_index).
-behaviour(gen_server).

-export([
    start_link/2,
    close/1,
    add/3,
    add_many/2,
    search/3,
    size/1,
    save/2,
    load/1
]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-record(state, {
    name     :: atom(),
    dim      :: pos_integer(),
    handle   :: reference(),
    path     :: file:filename_all() | undefined
}).

%%% API

start_link(Name, Opts) when is_atom(Name), is_map(Opts) ->
    gen_server:start_link({local, Name}, ?MODULE, {Name, Opts}, []).

close(IndexRef) ->
    gen_server:stop(IndexRef).

add(IndexRef, Id, Vector) ->
    gen_server:call(IndexRef, {add, Id, Vector}).

add_many(IndexRef, Pairs) ->
    gen_server:call(IndexRef, {add_many, Pairs}).

search(IndexRef, Query, TopK) ->
    gen_server:call(IndexRef, {search, Query, TopK}).

size(IndexRef) ->
    gen_server:call(IndexRef, size).

save(IndexRef, Path) ->
    gen_server:call(IndexRef, {save, Path}).

load(Path) ->
    {ok, Handle, Dim} = hecate_vector_nif:load(to_charlist(Path)),
    Name = list_to_atom("hecate_vector_loaded_" ++ integer_to_list(erlang:unique_integer([positive]))),
    hecate_vector_index_sup:start_index(Name, #{
        dim => Dim,
        handle => Handle,
        path => Path
    }).

%%% gen_server

init({Name, Opts}) ->
    Dim = maps:get(dim, Opts, 768),
    Cap = maps:get(capacity, Opts, 10000),
    Handle = case maps:get(handle, Opts, undefined) of
        undefined -> hecate_vector_nif:new(Dim, Cap);
        H         -> H
    end,
    Path = maps:get(path, Opts, undefined),
    {ok, #state{name = Name, dim = Dim, handle = Handle, path = Path}}.

handle_call({add, Id, Vector}, _From, #state{handle = H} = S) ->
    {reply, hecate_vector_nif:add(H, Id, Vector), S};
handle_call({add_many, Pairs}, _From, #state{handle = H} = S) ->
    {reply, hecate_vector_nif:add_many(H, Pairs), S};
handle_call({search, Query, TopK}, _From, #state{handle = H} = S) ->
    {reply, hecate_vector_nif:search(H, Query, TopK), S};
handle_call(size, _From, #state{handle = H} = S) ->
    {reply, hecate_vector_nif:size(H), S};
handle_call({save, Path}, _From, #state{handle = H} = S) ->
    Reply = hecate_vector_nif:save(H, to_charlist(Path)),
    {reply, Reply, S#state{path = Path}};
handle_call(_Other, _From, S) ->
    {reply, {error, unknown_call}, S}.

handle_cast(_Msg, S) -> {noreply, S}.
handle_info(_Msg, S) -> {noreply, S}.

terminate(_Reason, _S) -> ok.

%%% Internals

to_charlist(B) when is_binary(B) -> binary_to_list(B);
to_charlist(L) when is_list(L)   -> L.
