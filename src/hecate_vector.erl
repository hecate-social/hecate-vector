%%% @doc hecate_vector public facade.
%%%
%%% Open a named ANN index, add vectors with a binary id, search by
%%% cosine similarity, persist to disk. Each named index is a
%%% supervised gen_server backed by a Rustler NIF resource.
%%%
%%% Vectors are passed as lists of floats from Erlang. The NIF copies
%%% them into a flat Rust `Vec<f32>` once per call.
-module(hecate_vector).

-export([
    open/2,
    close/1,
    add/3,
    add_many/2,
    search/3,
    size/1,
    save/2,
    load/1
]).

-export_type([index/0, id/0, vector/0, hit/0, score/0]).

-type index()  :: pid() | atom().
-type id()     :: binary().
-type vector() :: [float()].
-type score()  :: float().
-type hit()    :: {id(), score()}.

%% @doc Open or get a named index.
%% Opts: #{dim => pos_integer(), capacity => pos_integer()}.
-spec open(atom(), map()) -> {ok, index()} | {error, term()}.
open(Name, Opts) ->
    case whereis(Name) of
        undefined ->
            hecate_vector_index_sup:start_index(Name, Opts);
        Pid ->
            {ok, Pid}
    end.

-spec close(index()) -> ok.
close(Index) ->
    hecate_vector_index:close(Index).

-spec add(index(), id(), vector()) -> ok | {error, term()}.
add(Index, Id, Vector) when is_binary(Id), is_list(Vector) ->
    hecate_vector_index:add(Index, Id, Vector).

-spec add_many(index(), [{id(), vector()}]) -> ok | {error, term()}.
add_many(Index, Pairs) when is_list(Pairs) ->
    hecate_vector_index:add_many(Index, Pairs).

-spec search(index(), vector(), pos_integer()) -> {ok, [hit()]} | {error, term()}.
search(Index, Query, TopK) when is_list(Query), is_integer(TopK), TopK > 0 ->
    hecate_vector_index:search(Index, Query, TopK).

-spec size(index()) -> non_neg_integer().
size(Index) ->
    hecate_vector_index:size(Index).

-spec save(index(), file:filename_all()) -> ok | {error, term()}.
save(Index, Path) ->
    hecate_vector_index:save(Index, Path).

-spec load(file:filename_all()) -> {ok, index()} | {error, term()}.
load(Path) ->
    hecate_vector_index:load(Path).
