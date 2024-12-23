use bls12_381::fp12::Fp12;
use bls12_381::pairings::{G1Affine, G2Affine, miller_loop};

// Optimized pairing from https://github.com/lambdaclass/lambdaworks/blob/2ce8b2ea2dd6547848b63db2246912b06066dd1b/math/src/elliptic_curve/short_weierstrass/curves/bls12_381/pairing.rs#L96
pub(crate) fn pairing_batch(p: (G1Affine, G2Affine), q: (G1Affine, G2Affine)) -> Fp12 {
    let mut res = Fp12::one();

    if !(p.0.infinity & p.1.infinity & q.0.infinity & q.1.infinity) {
        let p_miller = miller_loop(p.0, p.1);
        let q_miller = miller_loop(q.0, q.1);
        res = p_miller.mul(q_miller).final_exponentiation();
    }
    res
}
