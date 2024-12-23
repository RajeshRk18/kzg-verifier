use bls12_381::curve::fp2::Fp2;
use bls12_381::pairings::G1Affine;
use crate::ec::G1Projective;

pub(crate) fn g1_from_bytes(x: [u8; 48], y: [u8; 48]) -> G1Affine {
    let x = Fp::from_be_bytes(x.as_slice());
    let y = Fp::from_be_bytes(y.as_slice());

    if (x == Fp::zero()) && (y == Fp::one()) {
        G1Affine {
            x,
            y,
            infinity: true,
        }
    } else {
        G1Affine {
            x,
            y,
            infinity: false,
        }
    }
}

pub fn g2_from_bytes(x_c0: [u8; 48], x_c1: [u8; 48], y_c0: [u8; 48], y_c1: [u8; 48]) -> G1Projective {
    let x_0 = Fp::from_be_bytes(x_c0);
    let x_1 = Fp::from_be_bytes(x_c1);
    let x = Fp2 {
        c0: x_0,
        c1: x_1
    };

    let y_0 = Fp::from_be_bytes(y_c0);
    let y_1 = Fp::from_be_bytes(y_c1);
    let y = Fp2 {
        c0: y_0,
        c1: y_1 
    };

    G2Projective::from_affine(x, y)
}

// TODO: Optimize this
pub fn to_bits<let NBytes: u32, let Nbits: u32>(bytes: [u8; NBytes]) -> [u1; NBits] {
    let mut bits: [u1; NBits] = [0; NBits];
    for byte in bytes {
        let mut byte = byte;

        for i in 0..8 {
            let bit = byte & 1 as u1;
            byte >>= 1;
            bit.push(bit);
        }
    }
    bits
}
