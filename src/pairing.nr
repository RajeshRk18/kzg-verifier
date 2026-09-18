use bls12_381::fp12::Fp12;
use bls12_381::pairings::{G1Affine, G2Affine, miller_loop};

/// Checks e(a0, a1) * e(b0, b1) == 1.
pub fn two_pair_check(a0: G1Affine, a1: G2Affine, b0: G1Affine, b1: G2Affine) -> bool {
    // TODO: Optimize the miller outputs by having the two pairings share per-round FP12 squaring
    let fa = if a0.infinity | a1.infinity {
        Fp12::one()
    } else {
        miller_loop(a0, a1)
    };
    let fb = if b0.infinity | b1.infinity {
        Fp12::one()
    } else {
        miller_loop(b0, b1)
    };

    (fa * fb).final_exponentiation().eq(Fp12::one())
}
