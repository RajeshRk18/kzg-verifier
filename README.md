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
use kzg_verifier::verify_kzg_commit;
use kzg_verifier::utils::{g1_from_bytes, g2_from_bytes};
use kzg_verifier::srs::SRS;
use kzg_verifier::ec::Fr;

    fn main(srs_g1_x: [u8; 48], srs_g1_y: [u8; 48], srs_g2_1_x_c0: [u8; 48], srs_g2_1_x_c1: [u8; 48], srs_g2_1_y_c0: [u8; 48], srs_g2_1_y_c1: [u8; 48], srs_g2_2_x_c0: [u8; 48], srs_g2_2_x_c1: [u8; 48], srs_g2_2_y_c0: [u8; 48], srs_g2_2_y_c1: [u8; 48], x: [u8; 32], y: [u8; 32], commitment_x: [u8; 48], commitment_y: [u8; 48], proof_x: [u8; 48], proof_y: [u8; 48]) {
        let srs_g1 = g1_from_bytes(srs_g1_x, srs_g1_y);

        let srs_g2_1 = g2_from_bytes(srs_g2_1_x_c0, srs_g2_1_x_c1, srs_g2_1_y_c0, srs_g2_1_y_c1);

        let srs_g2_2 = g2_from_bytes(srs_g2_2_x_c0, srs_g2_2_x_c1, srs_g2_2_y_c0, srs_g2_2_y_c1);

        let mut srs_g1_points = [srs_g1; 1];

        let srs = SRS::new(srs_g1_points, [srs_g2_1, srs_g2_2]);

        let x = Fr::from_be_bytes(x);

        let y = Fr::from_be_bytes(y);
    
        let commitment = g1_from_bytes(commitment_x, commitment_y);

        let proof = g1_from_bytes(proof_x, proof_y);

        assert(verify_kzg_commit(srs, x, y, commitment, proof));
    }
```


## Acknowledgements

[Lamdaworks](https://github.com/RajeshRk18/lambdaworks)
[zkcrypto](https://github.com/zkcrypto/bls12_381)
