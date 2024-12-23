use bls12_381::fp2::{Fp, Fp2};
use bls12_381::pairings::{G1Affine, G2Projective};

pub(crate) fn g1_from_bytes(x: [u8; 48], y: [u8; 48]) -> G1Affine {
    let x = Fp::from_be_bytes(x);
    let y = Fp::from_be_bytes(y);

    if (x == Fp::new()) & (y == Fp::one()) {
        G1Affine { x, y, infinity: true }
    } else {
        G1Affine { x, y, infinity: false }
    }
}

pub fn g2_from_bytes(
    x_c0: [u8; 48],
    x_c1: [u8; 48],
    y_c0: [u8; 48],
    y_c1: [u8; 48],
) -> G2Projective {
    let x_0 = Fp::from_be_bytes(x_c0);
    let x_1 = Fp::from_be_bytes(x_c1);
    let x = Fp2 { c0: x_0, c1: x_1 };

    let y_0 = Fp::from_be_bytes(y_c0);
    let y_1 = Fp::from_be_bytes(y_c1);
    let y = Fp2 { c0: y_0, c1: y_1 };

    G2Projective { x, y, z: Fp2::one() }
}

// TODO: Optimize this
pub fn to_bits<let NBytes: u32, let NBits: u32>(bytes: [u8; NBytes]) -> [u1; NBits] {
    let mut bits: [u1; NBits] = [0; NBits];
    for i in 0..NBytes {
        let mut byte = bytes[i];

        for j in 0..8 {
            let bit = byte as u1;
            byte >>= 1;
            bits[i * j] = bit;
        }
    }
    bits
}
