# hecate_vector_nif

Rustler NIF crate backing the `hecate_vector` Erlang library.

This scaffold ships a **brute-force linear scan** implementation so the
BEAM side of the stack can integrate (build, test, call into the NIF)
before USearch is wired. The cosine similarity is correct; only the
search complexity is naive.

## Swap-in plan

1. Add `usearch = "2.x"` as a dependency, gate behind `hnsw` feature.
2. Replace `IndexInner` with a `usearch::Index`.
3. Map `add` → `index.add(label, slice)`, `search` → `index.search(slice, k)`.
4. Wire `save/load` to `usearch`'s built-in serialisation.

## Build

```bash
cargo build --release
```

`rebar3 compile` invokes this via `rebar3_cargo` from the parent project.
