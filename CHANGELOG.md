# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial scaffold: Rustler NIF skeleton, gen_server-per-index, facade
  module, build script, Common Test suite.
- Linear-scan placeholder NIF (correct shape, brute-force search) so the
  rest of the stack can integrate before USearch is wired.

### Planned
- Swap linear scan for USearch HNSW (`native/hecate_vector_nif`)
- Persistence (`save/2`, `load/1`) to memory-mapped file
- Metadata filter callbacks

## [0.1.0] - YYYY-MM-DD

_Not yet released._
