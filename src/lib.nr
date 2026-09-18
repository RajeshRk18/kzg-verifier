pub mod pairing;
pub mod serde;
mod tests;

use bignum::BLS12_381_Fr;
use bls12_381::pairings::{G1Affine, G2Affine};
use noir_bigcurve::{BigCurve, BLS12_381, BLS12_381Scalar};
use std::ops::Neg;

/// BLS12-381 scalar field element.
pub type Fr = BLS12_381_Fr;
/// BLS12-381 G1 point.
pub type G1 = BLS12_381;

/// The only key material a single-opening KZG verifier reads.
///
/// `g2` and `tau_g2` are trusted-setup outputs. Validate them off-circuit and
/// pin them. This library does not validate the points.
pub struct VerifierKey {
    pub g1: G1,
    pub g2: G2Affine,
    pub tau_g2: G2Affine,
}

impl VerifierKey {
    pub fn new(g1: G1, g2: G2Affine, tau_g2: G2Affine) -> Self {
        Self { g1, g2, tau_g2 }
    }

    /// Verifier key using the standard G1/G2 generators for a given `tau_g2`.
    pub fn from_tau_g2(g2: G2Affine, tau_g2: G2Affine) -> Self {
        Self { g1: BLS12_381::one(), g2, tau_g2 }
    }
}

fn to_affine(point: G1) -> G1Affine {
    G1Affine { x: point.x, y: point.y, infinity: point.is_infinity }
}

/// Verifies that commitment opens to `y` at `x` and returns result.
///
/// The textbook equation `e(C - y*G1, G2) == e(pi, tau*G2 - x*G2)` is rearranged
/// by bilinearity into `e(C - y*G1 + x*pi, G2) * e(-pi, tau*G2) == 1`, which
/// moves the evaluation point onto G1 and removes all G2 scalar multiplication.
pub fn verify_kzg(vk: VerifierKey, x: Fr, y: Fr, commitment: G1, proof: G1) -> bool {
    serde::validate_g1(commitment);
    serde::validate_g1(proof);

    // from_bignum calls validate_in_field, constraining both scalars to [0, r).
    let x_scalar = BLS12_381Scalar::from_bignum(x);
    let y_scalar = BLS12_381Scalar::from_bignum(y);

    // acc = commitment - y*G1 + x*proof
    let acc = BLS12_381::evaluate_linear_expression(
        [vk.g1.neg(), proof],
        [y_scalar, x_scalar],
        [commitment],
    );

    pairing::two_pair_check(to_affine(acc), vk.g2, to_affine(proof.neg()), vk.tau_g2)
}

/// `verify_kzg` but constrains the result
pub fn assert_kzg(vk: VerifierKey, x: Fr, y: Fr, commitment: G1, proof: G1) {
    assert(verify_kzg(vk, x, y, commitment, proof), "kzg opening is invalid");
}
