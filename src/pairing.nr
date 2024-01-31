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

#[test]
fn test_g1_mul() {
    let BLS12_381 { curve } = bls12_381();

    let x = [
        229, 46, 85, 206, 41, 42, 4, 15, 130, 248, 168, 57, 217, 198, 212, 219, 176, 229, 152, 7, 2, 11, 168, 161, 37, 74, 96, 39, 220, 207, 69, 45, 155, 109, 177, 196, 112, 199, 165, 13, 45, 231, 205, 250, 148, 180, 107, 3
    ];

    let y = [
        160, 11, 175, 133, 228, 165, 8, 24, 36, 108, 76, 174, 14, 27, 188, 115, 15, 117, 86, 12, 187, 30, 164, 77, 104, 22, 250, 237, 161, 192, 25, 64, 115, 86, 112, 210, 225, 110, 176, 83, 255, 0, 192, 156, 228, 246, 172, 7
    ];

    let point = G1Point::from_affine(PrimeField::from_bytes(x), PrimeField::from_bytes(y));

    let x = [
        92, 205, 238, 245, 74, 115, 129, 163, 205, 178, 95, 166, 104, 76, 175, 67, 77, 39, 172, 14, 170, 73, 216, 45, 9, 21, 191, 198, 39, 112, 53, 222, 59, 247, 9, 152, 12, 142, 145, 132, 3, 181, 30, 231, 231, 204, 43, 3
    ];
    let y = [
        136, 77, 149, 43, 69, 134, 81, 85, 27, 162, 133, 104, 234, 165, 104, 11, 137, 216, 41, 247, 230, 199, 221, 173, 202, 52, 5, 21, 30, 223, 15, 57, 215, 103, 75, 220, 66, 138, 124, 190, 170, 88, 148, 177, 103, 132, 228, 17
    ];
    let point_times_5 = G1Point::from_affine(PrimeField::from_bytes(x), PrimeField::from_bytes(y));

    assert(g1_scalar_mul(point, PrimeField::from_u56(5)).eq(point_times_5));
}

#[test]
fn test_g2_mul() {
    let BLS12_381G2 { curve } = bls12_381_g2();

    assert(g2_scalar_mul(curve.gen, PrimeField::from_u56(2)).eq(g2_add(curve.gen, curve.gen)));
}
