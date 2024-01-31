use dep::bls12_381::field::prime_field::PrimeField;
use dep::bls12_381::curve::g2::G2Point;
use dep::bls12_381::curve::swcurve::{Curve, Point as G1Point};
use dep::bls12_381::curve::fp12::Fp12;
use dep::bls12_381::curve::pairing::{pair, final_exponentiation, miller_loop};
use dep::bls12_381::curve::{bls12_381, bls12_381_g2, BLS12_381, BLS12_381G2 };

use dep::std;
fn g1_scalar_mul(point: G1Point, scalar: PrimeField) -> G1Point {
    let BLS12_381 { curve } = bls12_381();

    let mut res = G1Point::zero();
    let mut temp = point;

    for i in scalar.to_bits() {
        if i == 1 as u1 {
            res = g1_add(res, temp);
        }
        temp = curve.double(temp);
    }
    res
}

fn g2_scalar_mul(point: G2Point, scalar: PrimeField) -> G2Point {
    let BLS12_381G2 { curve } = bls12_381_g2();

    let mut res = G2Point::zero();
    let mut temp = point;

    for i in scalar.to_bits() {
        if i == 1 as u1 {
            res = g2_add(res, temp);
        }
        temp = curve.double(temp);
    }
    res
}

fn g1_add(point1: G1Point, point2: G1Point) -> G1Point {
    let BLS12_381 { curve } = bls12_381();

    curve.add(point1, point2)
}

fn g2_add(point1: G2Point, point2: G2Point) -> G2Point {
    let BLS12_381G2 { curve } = bls12_381_g2();

    curve.add(point1, point2)
}

fn compute_pairing(pair1: (G1Point, G2Point), pair2: (G1Point, G2Point)) -> Fp12 {
    let pair1_miller = miller_loop(pair1.1, pair1.0);
    let pair2_miller = miller_loop(pair2.1, pair2.0);

    final_exponentiation(pair1_miller.mul(pair2_miller))
}
