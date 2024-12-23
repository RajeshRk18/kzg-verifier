mod srs;
mod pairing;
mod utils;
mod ec;

use crate::ec::{
    Fr, G1Projective, g2_add, g2_multiply, g2_negate, g2_normalize,
    g2_projective,
};
use crate::pairing::pairing_batch;
use crate::srs::SRS;
use crate::utils::g1_from_bytes;
use bls12_381::fp12::Fp12;
use bls12_381::pairings::{G1Affine, G2Affine};

//
/// Performs the verification of a KZG Commitment.
/// Params:
///        SRS        : Structured Reference String from trusted setups.
///        x          : Evaluation Point
///        y          : Evaluation Result
///        commitment : Point obtained from committing
///        proof      : Opening Proof
//
pub fn verify_kzg_commit<let N: u32>(
    srs: SRS<N>,
    x: Fr,
    y: Fr,
    commitment: G1Affine,
    proof: G1Affine,
) -> bool {
    let g1 = srs.g1_points[0];
    let g2 = srs.g2_points[0];
    let shifted_g2 = g2_projective(srs.g2_points[1]);

    let g1_y_neg = G1Projective::from_affine(g1).mul(y).neg();
    let commitment = G1Projective::from_affine(commitment);
    let g1_y_neg_add_commit = g1_y_neg.add(commitment).normalize();

    let g2_x_neg = g2_negate(g2_multiply(g2_projective(g2), x));
    let g2_x_neg_add_shifted = g2_normalize(g2_add(g2_x_neg, shifted_g2));

    let pairing = pairing_batch(
        (g1_y_neg_add_commit, g2),
        (proof.neg(), g2_x_neg_add_shifted),
    );

    pairing.eq(Fp12::one())
}

// Test vector got using lambaworks
#[test]
fn test_verify1() {
    let mut toxic_waste = Fr::new();
    toxic_waste.limbs[0] = 20;

    let mut g1_points: [G1Affine; 20] = [G1Affine::generator(); 20];

    for i in 0..20 {
        let mut exponent = Fr::one();

        for _ in 0..i {
            exponent = toxic_waste.mul(exponent);
        }
        g1_points[i] = G1Projective::generator().mul(exponent).normalize();
    }

    let mut g2_points: [G2Affine; 2] = [G2Affine::generator(), G2Affine::generator()];
    g2_points[1] = g2_normalize(g2_multiply(g2_projective(g2_points[1]), toxic_waste));

    let srs = SRS::new(g1_points, g2_points);
    let x = Fr::from_be_bytes([
        0, 0, 0, 0, 255, 255, 255, 255, 254, 91, 254, 255, 2, 164, 189, 83, 5, 216, 161, 9, 8, 216,
        57, 51, 72, 125, 157, 41, 83, 167, 237, 115,
    ]);
    let y = Fr::new(); //zero
    let commit_x = [
        250, 17, 39, 156, 232, 47, 188, 65, 171, 184, 188, 208, 15, 255, 201, 206, 22, 199, 99, 89,
        241, 128, 200, 193, 83, 122, 25, 147, 97, 130, 9, 159, 199, 141, 240, 122, 69, 127, 167, 56,
        103, 79, 180, 84, 28, 167, 185, 7,
    ];
    let commit_y = [
        32, 160, 211, 141, 73, 104, 57, 232, 4, 2, 45, 140, 25, 194, 54, 58, 145, 64, 204, 144, 144,
        53, 70, 210, 100, 3, 164, 62, 181, 156, 207, 223, 49, 101, 37, 160, 67, 246, 2, 129, 91,
        219, 48, 248, 50, 119, 125, 15,
    ];
    let commitment = g1_from_bytes(commit_x, commit_y);
    let proof = G1Affine::generator();
    assert(verify_kzg_commit(srs, x, y, commitment, proof));
}
