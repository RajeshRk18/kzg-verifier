mod srs;
mod pairing;
mod utils;
mod ec;

use bls12_381::pairings::{G1Affine, G2Affine};
use bls12_381::fp12::Fp12;
use bls12_381::fp2::{Fp, Fp2};
use crate::srs::SRS;
use crate::ec::{G1Projective, g2_multiply, g2_add, g2_double, Fr};
use crate::pairing::pairing_batch;
use crate::utils::g1_from_bytes;

//
/// Performs the verification of a KZG Commitment.
/// Params:
///        SRS        : Structured Reference String from trusted setups.
///        x          : Evaluation Point
///        y          : Evaluation Result
///        commitment : Point obtained from committing
///        proof      : Opening Proof  
//
pub fn verify_kzg_commit<let PTAU: u32>(
    srs: SRS<PTAU>,
    x: Fr,
    y: Fr,
    commitment: G1Affine,
    proof: G2Affine
) -> bool {
    let g1 = srs.g1_points[0];
    let g2 = srs.g2_points[0];
    let shifted_g2 = srs.g2_points[1];

    let g1_y_neg = G1Projective::from_affine(g1).mul(y).negate(); //TODO
    let commitment = G1Projective::from_affine(commitment);
    let g1_y_neg_add_commit = g1_y_neg.add(commitment);

    let g2_x_neg = g2_negate(g2_multiply(g2_projective(g2), x));
    let g2_x_neg_add_shifted = g2_add(g2_x_neg, shifted_g2);
    //let a = g1_add(commitment, g1_scalar_mul(g1, y).negate());
    //let b = g2_add(shifted_g2, g2_scalar_mul(g2, x).negate());
    let pairing = pairing_batch((g2_x_neg_add_shifted, g2), (g1_y_neg_add_commit, proof.neg()));

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
    let y = Fp::new();
    let commit_x = [
        250, 17, 39, 156, 232, 47, 188, 65, 171, 184, 188, 208, 15, 255, 201, 206, 22, 199, 99, 89, 241, 128, 200, 193, 83, 122, 25, 147, 97, 130, 9, 159, 199, 141, 240, 122, 69, 127, 167, 56, 103, 79, 180, 84, 28, 167, 185, 7
    ];
    let commit_y = [
        32, 160, 211, 141, 73, 104, 57, 232, 4, 2, 45, 140, 25, 194, 54, 58, 145, 64, 204, 144, 144, 53, 70, 210, 100, 3, 164, 62, 181, 156, 207, 223, 49, 101, 37, 160, 67, 246, 2, 129, 91, 219, 48, 248, 50, 119, 125, 15
    ];
    let commitment = g1_from_bytes(commit_x, commit_y);
    let proof = G2Affine::generator();
    assert(verify_kzg_commit(srs, x, y, commitment, proof));
}
