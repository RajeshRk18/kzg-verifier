use dep::bls12_381_curve::bls12_381::g2::G2Point;
use dep::bls12_381_curve::bls12_381::swcurve::Point as G1Point;
use dep::std::collections::vec::Vec;

// Structured Reference String created from trusted setups
struct SRS {
    g1_points: Vec<G1Point>,
    g2_points: [G2Point; 2]
}

impl SRS {
    pub fn new(g1_points: Vec<G1Point>, g2_points: [G2Point; 2]) -> Self {
        Self {
            g1_points,
            g2_points
        }
    }
}