mod poly;
mod srs;
mod pairing;
mod utils;
mod ec;

use bls12_381::pairings::{G1Affine, G2Affine, miller_loop};
use bls12_381::fp12::Fp12;
use bls12_381::fp2::{Fp, Fp2};
use crate::srs::SRS;
use crate::pairing::{g1_scalar_mul, g2_scalar_mul, g1_add, g2_add, compute_pairing};

//
/// This performs the `verify` of KZG Commitment Scheme
/// Params:
///        SRS: Structured Reference String from trusted setups. It includes two

//
pub fn verify_kzg_commit(
    srs: SRS,
    x: Fp,
    y: Fp,
    commitment: G1Affine,
    proof: G2Affine
) -> bool {
    let g1 = srs.g1_points.get(0);
    let g2 = srs.g2_points[0];
    let shifted_g2 = srs.g2_points[1];

    let a = g1_add(commitment, g1_scalar_mul(g1, y).negate());
    let b = g2_add(shifted_g2, g2_scalar_mul(g2, x).negate());
    let pairing = pairing_batch((a, g2), (proof.negate(), b));

    pairing.eq(Fp12::one())
}

// Test vector got using lambaworks 
#[test]
fn test_verify1() {
    let mut toxic_waste = Fr::new();
    toxic_waste.limbs[0] = 20;

    let mut g1_points = Vec::new();

    for i in 0..20 {
        let mut exponent = Fr::one();

        for _j in 0..i {
            exponent = toxic_waste.mul(exponent);
        }
        g1_points.push(G1Projective::from_affine(G1Affine::generator()).mul(exponent));
    }

    let mut g2_points: [G2Projective; 2] = [g2_identity(), g2_identity()];
    g2_points[0] = g2_curve.gen;
    g2_points[1] = g2_scalar_mul(g2_curve.gen, toxic_waste);

    let srs = SRS::new(g1_points, g2_points);
    let x = Fr::from_be_bytes(
        [
        0, 0, 0, 0, 255, 255, 255, 255, 254, 91, 254, 255, 2, 164, 189, 83, 5, 216, 161, 9, 8, 216, 57, 51, 72, 125, 157, 41, 83, 167, 237, 115
    ]
    );
    let y = Fp::zero();
    let commit_x = [
        250, 17, 39, 156, 232, 47, 188, 65, 171, 184, 188, 208, 15, 255, 201, 206, 22, 199, 99, 89, 241, 128, 200, 193, 83, 122, 25, 147, 97, 130, 9, 159, 199, 141, 240, 122, 69, 127, 167, 56, 103, 79, 180, 84, 28, 167, 185, 7
    ];
    let commit_y = [
        32, 160, 211, 141, 73, 104, 57, 232, 4, 2, 45, 140, 25, 194, 54, 58, 145, 64, 204, 144, 144, 53, 70, 210, 100, 3, 164, 62, 181, 156, 207, 223, 49, 101, 37, 160, 67, 246, 2, 129, 91, 219, 48, 248, 50, 119, 125, 15
    ];
    let commitment = G1Projective::from_affine(g1_from_bytes(commit_x, commit_y));
    let proof = g1_curve.gen;
    assert(verify_kzg_commit(srs, x, y, commitment, proof));
}
