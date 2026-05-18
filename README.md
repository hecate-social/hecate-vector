# hecate-vector

In-BEAM approximate-nearest-neighbour (ANN) index for the Hecate ecosystem.

A thin Erlang/OTP wrapper around a Rust HNSW core (USearch in the production
build; an in-memory linear scan in this scaffold) exposed via Rustler NIFs.
Built to back retrieval-augmented generation (RAG) inside the Hecate
daemon without a sidecar database.

## Status

**Scaffold.** API surface exists, NIF stubs return correct shapes but use
brute-force linear search. Wire up USearch via the `hecate_vector_nif`
Rust crate before relying on it at scale.

## Why

- Local-first: index lives next to the daemon, no Postgres, no Qdrant pod
- Sovereign stack: pure-Rust core, Apache-2.0 only
- BEAM-native: a Rustler NIF, no sidecar process, no IPC tax
- Designed to be sharded across stations via [`macula-rag`](https://codeberg.org/macula-io/macula-rag)

## Public API

```erlang
{ok, Index} = hecate_vector:open(my_corpus, #{dim => 768, capacity => 100000}).
ok          = hecate_vector:add(Index, <<"chunk-001">>, Vector).
{ok, Hits}  = hecate_vector:search(Index, QueryVector, 5).
ok          = hecate_vector:save(Index, "priv/index/my_corpus.hvec").
{ok, Index} = hecate_vector:load("priv/index/my_corpus.hvec").
```

`Vector` is a list of floats. `Hits` is `[{Id :: binary(), Score :: float()}]`
sorted descending by cosine similarity.

## Architecture

```
hecate_vector              ← public facade
  └── hecate_vector_index  ← gen_server per open index (lifecycle, persistence)
        └── hecate_vector_nif ← Rustler NIF
              └── native/hecate_vector_nif/  ← Rust crate (USearch / scaffold)
```

Each open index is a supervised gen_server holding a NIF resource handle.
`hecate_vector_index_sup` is a `simple_one_for_one` dynamic supervisor.

## Build

```bash
rebar3 compile           # also builds the Rust NIF via rebar3_cargo
rebar3 ct                # runs Common Test suites
```

The NIF library lands under `priv/lib/libhecate_vector_nif.{so,dylib,dll}`.

## Dependencies

- [USearch](https://github.com/unum-cloud/usearch) (Apache-2.0) - HNSW core, wired in production builds
- [Rustler](https://github.com/rusterlium/rustler) - Erlang/Rust NIF bridge

## Status table

| Capability | Scaffold | Production |
|------------|----------|------------|
| `open/2`, `close/1` | ✅ | ✅ |
| `add/3`, `add_many/2` | ✅ | ✅ |
| `search/3` (linear scan) | ✅ | — |
| `search/3` (HNSW) | — | ⏳ swap NIF impl |
| `save/2`, `load/1` | ✅ stub | ⏳ |
| Metadata filters | — | ⏳ |

## License

Apache-2.0. See [LICENSE](LICENSE).
