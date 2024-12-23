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
use dep::kzg_verifier::utils::{create_g1_point, create_g2_point};
use dep::kzg_verifier::srs::SRS;
use dep::bls12_381::field::prime_field::PrimeField as Fp;

    fn main(srs_g1_x: [u8; 48], srs_g1_y: [u8; 48], srs_g2_1_x_c0: [u8; 48], srs_g2_1_x_c1: [u8; 48], srs_g2_1_y_c0: [u8; 48], srs_g2_1_y_c1: [u8; 48], srs_g2_2_x_c0: [u8; 48], srs_g2_2_x_c1: [u8; 48], srs_g2_2_y_c0: [u8; 48], srs_g2_2_y_c1: [u8; 48], x: [u8; 48], y: [u8; 48], pub commitment_x: [u8; 48], pub commitment_y: [u8; 48], pub proof_x: [u8; 48], pub proof_y: [u8; 48]) -> bool {
        let srs_g1 = create_g1_point(srs_g1_x, srs_g1_y);

        let srs_g2_1 = create_g2_point(srs_g2_1_x_c0, srs_g2_1_x_c1, srs_g2_1_y_c0, srs_g2_1_y_c1);

        let srs_g2_2 = create_g2_point(srs_g2_2_x_c0, srs_g2_2_x_c1, srs_g2_2_y_c0, srs_g2_2_y_c1);

        let mut srs_g1_points = Vec::new();
        srs_g1_points.push(srs_g1);

        let srs = SRS::new(srs_g1_points, [srs_g2_1, srs_g2_2]);

        let x = Fp::from_bytes(x);

        let y = Fp::from_bytes(y);
    
        let commitment = create_g1_point(commitment_x, commitment_y);

        let proof = create_g1_point(proof_x, proof_y);

        assert(verify_kzg_commit(srs, x, y, commitment, proof))
    }
```

## Limitations

- BLS12_381 curve is supported currently.


## Acknowledgements

[Lamdaworks](https://github.com/RajeshRk18/lambdaworks)

