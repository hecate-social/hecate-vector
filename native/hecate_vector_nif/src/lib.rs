//! hecate_vector_nif
//!
//! Rustler NIF backing `hecate_vector`. Scaffold implementation uses a
//! brute-force linear scan over `Vec<(Id, Vec<f32>)>`; production build
//! should swap in USearch's HNSW under the `hnsw` cargo feature.
//!
//! Cosine similarity is computed in `O(N * dim)`. For corpora up to
//! a few thousand vectors this is fine; past that, enable `hnsw`.

use rustler::{Atom, Binary, Encoder, Env, NifResult, OwnedBinary, ResourceArc, Term};
use std::sync::Mutex;

mod atoms {
    rustler::atoms! {
        ok,
        error,
        dim_mismatch,
        not_implemented,
    }
}

struct IndexResource {
    inner: Mutex<IndexInner>,
}

struct IndexInner {
    dim: usize,
    items: Vec<(Vec<u8>, Vec<f32>)>,
}

#[rustler::nif]
fn new(dim: usize, _capacity: usize) -> ResourceArc<IndexResource> {
    ResourceArc::new(IndexResource {
        inner: Mutex::new(IndexInner {
            dim,
            items: Vec::new(),
        }),
    })
}

#[rustler::nif]
fn add<'a>(env: Env<'a>, handle: ResourceArc<IndexResource>, id: Binary<'a>, vector: Vec<f32>) -> NifResult<Term<'a>> {
    let mut guard = handle.inner.lock().unwrap();
    if vector.len() != guard.dim {
        return Ok((atoms::error(), atoms::dim_mismatch()).encode(env));
    }
    guard.items.push((id.as_slice().to_vec(), vector));
    Ok(atoms::ok().encode(env))
}

#[rustler::nif]
fn add_many<'a>(env: Env<'a>, handle: ResourceArc<IndexResource>, pairs: Vec<(Binary<'a>, Vec<f32>)>) -> NifResult<Term<'a>> {
    let mut guard = handle.inner.lock().unwrap();
    for (id, vector) in pairs {
        if vector.len() != guard.dim {
            return Ok((atoms::error(), atoms::dim_mismatch()).encode(env));
        }
        guard.items.push((id.as_slice().to_vec(), vector));
    }
    Ok(atoms::ok().encode(env))
}

#[rustler::nif]
fn search<'a>(env: Env<'a>, handle: ResourceArc<IndexResource>, query: Vec<f32>, top_k: usize) -> NifResult<Term<'a>> {
    let guard = handle.inner.lock().unwrap();
    if query.len() != guard.dim {
        return Ok((atoms::error(), atoms::dim_mismatch()).encode(env));
    }

    let qnorm = norm(&query);
    let mut scored: Vec<(&[u8], f32)> = guard
        .items
        .iter()
        .map(|(id, v)| {
            let s = cosine(&query, qnorm, v);
            (id.as_slice(), s)
        })
        .collect();

    scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    scored.truncate(top_k);

    let hits: Vec<Term> = scored
        .into_iter()
        .map(|(id, score)| {
            let mut bin = OwnedBinary::new(id.len()).unwrap();
            bin.as_mut_slice().copy_from_slice(id);
            (Binary::from_owned(bin, env), score).encode(env)
        })
        .collect();

    Ok((atoms::ok(), hits).encode(env))
}

#[rustler::nif]
fn size(handle: ResourceArc<IndexResource>) -> usize {
    handle.inner.lock().unwrap().items.len()
}

#[rustler::nif]
fn save<'a>(env: Env<'a>, _handle: ResourceArc<IndexResource>, _path: String) -> NifResult<Term<'a>> {
    // TODO: serialise items to memory-mapped file. Use bincode + zstd
    // when this stops being a scaffold.
    Ok((atoms::error(), atoms::not_implemented()).encode(env))
}

#[rustler::nif]
fn load<'a>(env: Env<'a>, _path: String) -> NifResult<Term<'a>> {
    // TODO: mirror save/2.
    Ok((atoms::error(), atoms::not_implemented()).encode(env))
}

fn norm(v: &[f32]) -> f32 {
    v.iter().map(|x| x * x).sum::<f32>().sqrt()
}

fn cosine(q: &[f32], qnorm: f32, v: &[f32]) -> f32 {
    let dot: f32 = q.iter().zip(v).map(|(a, b)| a * b).sum();
    let denom = qnorm * norm(v);
    if denom == 0.0 { 0.0 } else { dot / denom }
}

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource!(IndexResource, env);
    true
}

rustler::init!(
    "hecate_vector_nif",
    [new, add, add_many, search, size, save, load],
    load = on_load
);
