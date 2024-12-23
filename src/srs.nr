use bls12_381::pairings::{G1Affine, G2Affine};

//
/// Structured Reference String created from trusted setups
//
pub struct SRS<let N: u32> {
    g1_points: [G1Affine; N],
    g2_points: [G2Affine; 2]
}

impl<let N: u32> SRS<N> {
    pub fn new(g1_points: [G1Point; N], g2_points: [G2Point; 2]) -> Self {
        Self {
            g1_points,
            g2_points
        }
    }
}
