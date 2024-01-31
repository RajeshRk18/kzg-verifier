## About
A KZG commitment verifier written in Noir. 

## Installation
Add this in your Nargo.toml

```Rust
kzg_verifier = { tag = "v0.1.0", git = "https://github.com/RajeshRk18/kzg-verifier.git" }
```

## Usage

Required inputs:

- Structured Reference String (obtained from trusted setup)
- $x$ - Evaluation Point
- $y$ - Evaluation of $P(x)$
- Commitment $C$
- Evaluation Proof $\pi$

```rust
use dep::kzg_verifier::verify_kzg_commit;

fn main() -> bool {
    assert(verify_kzg_commit(srs, x, y, commitment, proof))
}
```

## Acknowledgements

[Lamdaworks](https://github.com/RajeshRk18/lambdaworks)

## Disclaimer
This is experimental software and is provided on an "as is" and "as available" basis. We do not give any warranties and will not be liable for any losses incurred through any use of this code base.