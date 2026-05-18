%%% @doc Rustler NIF entry module.
%%%
%%% Loads `priv/lib/libhecate_vector_nif.{so,dylib,dll}`. Every export
%%% here has a Rust implementation in `native/hecate_vector_nif/src/lib.rs`.
%%% The Erlang bodies are placeholders that error out if the NIF failed
%%% to load — they should never be hit at runtime.
-module(hecate_vector_nif).

-export([
    new/2,
    add/3,
    add_many/2,
    search/3,
    size/1,
    save/2,
    load/1
]).

-on_load(init/0).

-define(NIF_NOT_LOADED, erlang:nif_error({nif_not_loaded, ?MODULE})).

-spec init() -> ok | {error, term()}.
init() ->
    PrivDir = case code:priv_dir(hecate_vector) of
        {error, _} ->
            %% Test / dev tree: rebar puts us in _build/.../hecate_vector/ebin
            EbinDir = filename:dirname(code:which(?MODULE)),
            filename:join(filename:dirname(EbinDir), "priv");
        Dir ->
            Dir
    end,
    SoPath = filename:join([PrivDir, "lib", "libhecate_vector_nif"]),
    erlang:load_nif(SoPath, 0).

%% @doc Create a new in-memory index with `Dim`-element vectors,
%% reserving room for `Capacity` items.
-spec new(pos_integer(), pos_integer()) -> reference().
new(_Dim, _Capacity) -> ?NIF_NOT_LOADED.

%% @doc Insert one vector under the given binary id.
-spec add(reference(), binary(), [float()]) -> ok | {error, term()}.
add(_Handle, _Id, _Vector) -> ?NIF_NOT_LOADED.

%% @doc Insert many vectors in one call. Returns `ok' or an error
%% tuple after the first failure.
-spec add_many(reference(), [{binary(), [float()]}]) -> ok | {error, term()}.
add_many(_Handle, _Pairs) -> ?NIF_NOT_LOADED.

%% @doc Find the `TopK` nearest neighbours by cosine similarity.
%% Returns `{ok, [{Id :: binary(), Score :: float()}]}'.
-spec search(reference(), [float()], pos_integer()) ->
    {ok, [{binary(), float()}]} | {error, term()}.
search(_Handle, _Query, _TopK) -> ?NIF_NOT_LOADED.

%% @doc Current number of indexed items.
-spec size(reference()) -> non_neg_integer().
size(_Handle) -> ?NIF_NOT_LOADED.

%% @doc Serialise to disk.
-spec save(reference(), string()) -> ok | {error, term()}.
save(_Handle, _Path) -> ?NIF_NOT_LOADED.

%% @doc Restore from disk. Returns `{ok, Handle, Dim}'.
-spec load(string()) -> {ok, reference(), pos_integer()} | {error, term()}.
load(_Path) -> ?NIF_NOT_LOADED.
