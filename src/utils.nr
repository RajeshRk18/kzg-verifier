use dep::bls12_381::field::prime_field::PrimeField as Fp;
use dep::bls12_381::curve::fp2::Fp2;
use dep::bls12_381::curve::g2::G2Point;
use dep::bls12_381::curve::swcurve::Point as G1Point;

// f([x_0, .., x_47], [y_0,.., y_47]) -> (X, Y, Z) in G_1
// Range check and membership check are performed.
pub(crate) fn create_g1_point(x: [u8; 48], y: [u8; 48]) -> G1Point {
    let x = Fp::from_bytes(x.as_slice());
    let y = Fp::from_bytes(y.as_slice());
    G1Point::from_affine(x, y)
}

//        x_c0      |       x_c1      |       y_c0    |         y_c1
// f([x_0, .., x_47], [x_48, .., x_95], [y_0,.., y_47], [y_48,.., y_95]) -> (X, Y, Z) in G_2
// Range check and membership check are performed.
pub(crate) fn create_g2_point(x_c0: [u8; 48], x_c1: [u8; 48], y_c0: [u8; 48], y_c1: [u8; 48]) -> G2Point {
    let x_0 = Fp::from_bytes(x_c0.as_slice());
    let x_1 = Fp::from_bytes(x_c1.as_slice());
    let x = Fp2::new(x_0, x_1);

    let y_0 = Fp::from_bytes(y_c0.as_slice());
    let y_1 = Fp::from_bytes(y_c1.as_slice());
    let y = Fp2::new(y_0, y_1);

    G2Point::from_affine(x, y)
}
