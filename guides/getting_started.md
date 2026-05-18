# Getting started

`hecate_vector` lets you open one or more named ANN indexes inside a
running BEAM node, add vectors, and search by cosine similarity. It is
the storage layer that backs RAG in the Hecate ecosystem.

## Install

```erlang
%% rebar.config
{deps, [
    {hecate_vector, "~> 0.1"}
]}.
```

`rebar3 compile` will fetch the dep and build the Rust NIF.

## Open an index

```erlang
{ok, Idx} = hecate_vector:open(my_docs, #{
    dim      => 768,
    capacity => 100000
}).
```

Indexes are registered under the name you pass. Calling `open/2` again
with the same name is a no-op (returns the existing pid).

## Add vectors

```erlang
ok = hecate_vector:add(Idx, <<"chunk:readme:0">>, Vector).
ok = hecate_vector:add_many(Idx, [
    {<<"chunk:soul:0">>,   V1},
    {<<"chunk:soul:1">>,   V2},
    {<<"chunk:ddd:0">>,    V3}
]).
```

`Vector` is a list of floats. Length must match the index `dim`.

## Search

```erlang
{ok, Hits} = hecate_vector:search(Idx, QueryVector, 5).
%% Hits :: [{<<"chunk:soul:0">>, 0.91}, {<<"chunk:ddd:0">>, 0.84}, ...]
```

Returned hits are sorted by descending cosine similarity. Score is in
`[-1.0, 1.0]`.

## Persistence

```erlang
ok        = hecate_vector:save(Idx, "priv/index/my_docs.hvec").
{ok, Idx} = hecate_vector:load("priv/index/my_docs.hvec").
```

The on-disk format is opaque (memory-mapped file produced by the Rust
side). Don't try to read it from Erlang.

## Embedding

`hecate_vector` doesn't compute embeddings. Pair it with
[`hecate_embed`](https://codeberg.org/hecate-social/hecate-embed):

```erlang
{ok, Vec} = hecate_embed:embed(<<"the dossier moves through desks">>),
ok        = hecate_vector:add(Idx, <<"chunk:1">>, Vec).
```
