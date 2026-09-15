use bignum::{BigNum, BLS12_381_Fq, BLS12_381_Fr};
use bls12_381::fp2::Fp2;
use bls12_381::pairings::G2Affine;
use noir_bigcurve::{BigCurve, BLS12_381, BLS12_381Scalar};
use std::ops::Neg;

/// BLS12-381 scalar field modulus `r`, big-endian.
global R_BE: [u8; 32] = [
    115, 237, 167, 83, 41, 157, 125, 72, 51, 57, 216, 8, 9, 161, 216, 5, 83, 189, 164, 2, 255, 254,
    91, 254, 255, 255, 255, 255, 0, 0, 0, 1,
];

/// BLS12-381 base field modulus `q`, big-endian.
global Q_BE: [u8; 48] = [
    26, 1, 17, 234, 57, 127, 230, 154, 75, 27, 167, 182, 67, 75, 172, 215, 100, 119, 75, 132, 243,
    133, 18, 191, 103, 48, 210, 160, 246, 176, 246, 36, 30, 171, 255, 254, 177, 83, 255, 255, 185,
    254, 255, 255, 255, 255, 170, 171,
];

/// Asserts `bytes < modulus`, comparing big-endian.
///
/// bignum v0.10's `from_be_bytes` accepts values in `[modulus, 2^MOD_BITS)`
/// (verified for `r`, `r + 1` and `2^255 - 1`), so canonicality is enforced here
/// rather than assumed from the dependency.
fn assert_canonical<let N: u32>(bytes: [u8; N], modulus: [u8; N]) {
    let mut less = false;
    let mut decided = false;
    for i in 0..N {
        if !decided {
            if bytes[i] < modulus[i] {
                less = true;
                decided = true;
            } else if bytes[i] > modulus[i] {
                decided = true;
            }
        }
    }
    assert(less, "value is not canonical: >= modulus");
}

/// Decodes a scalar from 32 big-endian bytes, constrained to `[0, r)`.
pub fn fr_from_be_bytes(bytes: [u8; 32]) -> BLS12_381_Fr {
    assert_canonical(bytes, R_BE);
    BLS12_381_Fr::from_be_bytes(bytes)
}

/// Decodes a base field element from 48 big-endian bytes, constrained to `[0, q)`.
pub fn fq_from_be_bytes(bytes: [u8; 48]) -> BLS12_381_Fq {
    assert_canonical(bytes, Q_BE);
    BLS12_381_Fq::from_be_bytes(bytes)
}

/// Decodes a G1 point from uncompressed big-endian coordinates and fully
/// validates it: canonical `[0, q)` coordinates, on-curve, and in the
/// prime-order subgroup. This is the trust boundary for untrusted G1 input.
pub fn g1_from_be_bytes(x: [u8; 48], y: [u8; 48]) -> BLS12_381 {
    let point = BLS12_381 { x: fq_from_be_bytes(x), y: fq_from_be_bytes(y), is_infinity: false };
    validate_g1(point);
    point
}

/// Asserts a G1 point is on the curve and in the prime-order subgroup.
pub fn validate_g1(point: BLS12_381) {
    point.validate_on_curve();
    assert(in_subgroup(point), "g1 point is not in the prime-order subgroup");
}

/// `[r]P == O`, expressed as `[r-1]P == -P` so the scalar stays inside `Fr`.
///
/// ponytail: one full scalar multiplication per point. The Bowe endomorphism
/// check is cheaper but needs its own review; this form is the definition.
pub fn in_subgroup(point: BLS12_381) -> bool {
    if point.is_infinity {
        true
    } else {
        let r_minus_1 = BLS12_381Scalar::from_bignum(BLS12_381_Fr::one().neg());
        point.mul(r_minus_1) == point.neg()
    }
}

/// Decodes a G2 point from uncompressed big-endian `(c0, c1)` coordinates.
///
/// No curve or subgroup validation: G2 points here are trusted-setup material.
/// Validate them off-circuit once and bind them to the verifier key.
pub fn g2_from_be_bytes(
    x_c0: [u8; 48],
    x_c1: [u8; 48],
    y_c0: [u8; 48],
    y_c1: [u8; 48],
) -> G2Affine {
    G2Affine {
        x: Fp2 { c0: fq_from_be_bytes(x_c0), c1: fq_from_be_bytes(x_c1) },
        y: Fp2 { c0: fq_from_be_bytes(y_c0), c1: fq_from_be_bytes(y_c1) },
        infinity: false,
    }
}
