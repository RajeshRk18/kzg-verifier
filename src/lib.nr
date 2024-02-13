use dep::bls12_381::field::prime_field::PrimeField;
use dep::bls12_381::curve::g2::G2Point;
use dep::bls12_381::curve::swcurve::{Curve, Point as G1Point};
use dep::bls12_381::curve::fp12::Fp12;
use dep::bls12_381::curve::pairing::{pair, final_exponentiation, miller_loop};
use dep::bls12_381::curve::{bls12_381, bls12_381_g2, BLS12_381, BLS12_381G2};
use dep::std::collections::vec::Vec;

mod poly;
mod srs;
mod pairing;

use crate::srs::SRS;
use crate::pairing::{g1_scalar_mul, g2_scalar_mul, g1_add, g2_add, compute_pairing};

pub fn verify_kzg_commit(
    srs: SRS,
    x: PrimeField,
    y: PrimeField,
    commitment: G1Point,
    proof: G1Point
) -> bool {
    let g1 = srs.g1_points.get(0);
    let g2 = srs.g2_points[0];
    let shifted_g2 = srs.g2_points[1];

    let a = g1_add(commitment, g1_scalar_mul(g1, y).negate());
    let b = g2_add(shifted_g2, g2_scalar_mul(g2, x).negate());
    let pairing = compute_pairing((a, g2), (proof.negate(), b));

    pairing.eq(Fp12::one())
}

#[test]
fn test_verify1() {
    let toxic_waste = PrimeField::from_u56(100 as u56);

    let BLS12_381 { curve } = bls12_381();
    let g1_curve = curve;

    let BLS12_381G2 { curve } = bls12_381_g2();
    let g2_curve = curve;

    let mut g1_points = Vec::new();

    for i in 0..50 {
        let mut exponent = PrimeField::one();

        for _j in 0..i {
            exponent = toxic_waste.mul(exponent);
        }
        g1_points.push(g1_scalar_mul(g1_curve.gen, exponent));
    }

    let mut g2_points: [G2Point; 2] = [G2Point::zero(), G2Point::zero()];
    g2_points[0] = g2_curve.gen;
    g2_points[1] = g2_scalar_mul(g2_curve.gen, toxic_waste);

    let srs = SRS::new(g1_points, g2_points);
    let x = PrimeField::from_bytes(
        [
        0, 0, 0, 0, 255, 255, 255, 255, 254, 91, 254, 255, 2, 164, 189, 83, 5, 216, 161, 9, 8, 216, 57, 51, 72, 125, 157, 41, 83, 167, 237, 115
    ]
    );
    let y = PrimeField::zero();
    let commitment = G1Point::from_affine(
        PrimeField::from_bytes(
            [
        250, 17, 39, 156, 232, 47, 188, 65, 171, 184, 188, 208, 15, 255, 201, 206, 22, 199, 99, 89, 241, 128, 200, 193, 83, 122, 25, 147, 97, 130, 9, 159, 199, 141, 240, 122, 69, 127, 167, 56, 103, 79, 180, 84, 28, 167, 185, 7
    ]
        ),
        PrimeField::from_bytes(
            [
        32, 160, 211, 141, 73, 104, 57, 232, 4, 2, 45, 140, 25, 194, 54, 58, 145, 64, 204, 144, 144, 53, 70, 210, 100, 3, 164, 62, 181, 156, 207, 223, 49, 101, 37, 160, 67, 246, 2, 129, 91, 219, 48, 248, 50, 119, 125, 15
    ]
        )
    );
    let proof = g1_curve.gen;
    assert(verify_kzg_commit(srs, x, y, commitment, proof));
}
