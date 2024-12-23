use bls12_381::pairings::{G1Affine, G2Affine, miller_loop};
use bls12_381::fp2::Fp;
use bignum::BigNum;
use bignum::fields::bls12_381Fq::BLS12_381_Fq_Params;
use crate::utils::to_bits;

// Scalar Field
pub type Fr = BigNum<4, 255, BLS12_381_Fr_Params>;
global SCALAR_NUM_BITS: u32 = 255 as u32; // Scalar Field Modulus Bit length

//
/// G1 Projective
//
pub(crate) struct G1Projective {
    x: Fp,
    y: Fp,
    z: Fp,
}

// Ref: https://eprint.iacr.org/2015/1060.pdf
impl G1Projective {
    // TODO: Do we need to validate the point?
    pub fn from_affine(point: G1Affine) -> Self {
        let z = if point.is_identity { Fp::zero() } else { Fp::one() };
        G1Projective {
            x: point.x,
            y: poiny.y,
            z,
        }
    }

    pub fn is_identity(&self) -> bool {
        self.z == Fp::zero()
    }

    // converts to coordinates in affine space
    pub fn normalize(&self) -> G1Affine {
        let mut affine_point = G1Affine::identity();
        unsafe {
            let z_inv = self.z.__invmod();
            assert(z_inv * self.z == Fp::one()); 
            // We dont need to check if z_inv is zero before normalizing because the above assertion will fail. 
            let norm_x = self.x * z_inv;
            let norm_y = self.y * z_inv;
            affine_point.x = norm_x;
            affine_point.y = norm_y;
            affine_point.infinity = false;
        }

        affine_point
    }

    pub fn double(&self) -> G1Projective {
        let t0 = self.y * self.y;
        let z3 = t0 + t0;
        let z3 = z3 + z3;
        let z3 = z3 + z3;
        let t1 = self.y * self.z;
        let t2 = self.z * self.z;
        let t2 = t2 * g1_b3();
        let x3 = t2 * z3;
        let y3 = t0 + t2;
        let z3 = t1 * z3;
        let t1 = t2 + t2;
        let t2 = t1 + t2;
        let t0 = t0 - t2;
        let y3 = t0 * y3;
        let y3 = x3 + y3;
        let t1 = self.x * self.y;
        let x3 = t0 * t1;
        let x3 = x3 + x3;

        let tmp = G1Projective {
            x: x3,
            y: y3,
            z: z3,
        };

        let mut res = G1Projective::identity();
        if !self.is_identity() {
            res = tmp;
        }

        res
    }

    pub fn add(&self, rhs: &G1Projective) -> G1Projective {
        let t0 = self.x * rhs.x;
        let t1 = self.y * rhs.y;
        let t2 = self.z * rhs.z;
        let t3 = self.x + self.y;
        let t4 = rhs.x + rhs.y;
        let t3 = t3 * t4;
        let t4 = t0 + t1;
        let t3 = t3 - t4;
        let t4 = self.y + self.z;
        let x3 = rhs.y + rhs.z;
        let t4 = t4 * x3;
        let x3 = t1 + t2;
        let t4 = t4 - x3;
        let x3 = self.x + self.z;
        let y3 = rhs.x + rhs.z;
        let x3 = x3 * y3;
        let y3 = t0 + t2;
        let y3 = x3 - y3;
        let x3 = t0 + t0;
        let t0 = x3 + t0;
        let t2 = t2 * g1_b3();
        let z3 = t1 + t2;
        let t1 = t1 - t2;
        let y3 = y3 * g1_b3();
        let x3 = t4 * y3;
        let t2 = t3 * t1;
        let x3 = t2 - x3;
        let y3 = y3 * t0;
        let t1 = t1 * z3;
        let y3 = t1 + y3;
        let t0 = t0 * t3;
        let z3 = z3 * t4;
        let z3 = z3 + t0;

        G1Projective {
            x: x3,
            y: y3,
            z: z3,
        }
    }

    pub fn mul(&self, scalar: Fr) -> Self {
        let mut acc = G1Projective::identity();
        let mut temp = self;
        let mut scalar_bytes = scalar.to_le_bytes();
        
        let bits = to_bits::<32, SCALAR_NUM_BITS>(scalar_bytes);

        for bit in 0..bits {
            if bit == 1 as u1 {
                acc = temp.add(acc);
            }
            temp = temp.double();
        }
        acc
    }
}

// https://github.com/zkcrypto/bls12_381/blob/9ea427c0eb1a7e2ac16902a322aea156c496ddb0/src/g1.rs#L176
fn g1_b3() -> Fp {
    let b = Fp::from_be_bytes([170, 39, 0, 0, 0, 12, 255, 243, 83, 204, 0, 50, 252, 52, 0, 10, 71, 143, 233, 122, 107, 10, 128, 127, 177, 211, 126, 190, 230, 186, 36, 215, 142, 201, 115, 59, 191, 120, 171, 47, 9, 214, 69, 81, 61, 131, 222, 126]);
    b + b + b
}

// https://github.com/zkcrypto/bls12_381/blob/9ea427c0eb1a7e2ac16902a322aea156c496ddb0/src/g2.rs#L177
fn g2_b3() -> Fp2 {
    let x_0 = Fp::from_be_bytes([170, 39, 0, 0, 0, 12, 255, 243, 83, 204, 0, 50, 252, 52, 0, 10, 71, 143, 233, 122, 107, 10, 128, 127, 177, 211, 126, 190, 230, 186, 36, 215, 142, 201, 115, 59, 191, 120, 171, 47, 9, 214, 69, 81, 61, 131, 222, 126]);
    let x_1 = Fp::from_be_bytes([170, 39, 0, 0, 0, 12, 255, 243, 83, 204, 0, 50, 252, 52, 0, 10, 71, 143, 233, 122, 107, 10, 128, 127, 177, 211, 126, 190, 230, 186, 36, 215, 142, 201, 115, 59, 191, 120, 171, 47, 9, 214, 69, 81, 61, 131, 222, 126]);
    
    let b = Fp2 {
        c0: x_0,
        c1: x_1
    };
    b + b + b
}

//
/// Extending G2 from https://github.com/ewynx/noir_bls12_381_pairing/blob/99319731cc9ece4b4469ac8a0afe92fda5771020/src/pairings.nr#L8
//

pub fn g2_identity() -> G2Affine {
    G2Affine {
        x: Fp2::zero(),
        y: FP2::one(),
        infinity: true,
    }
}

pub fn g2_is_identity(p: G2Projective) -> bool {
    (p.z.c0 == Fp::zero()) && (p.z.c1 == Fp::zero())
}

pub fn g2_generator() -> G2Projective {
    let x_0 = Fp::from_be_bytes([245, 242, 143, 162, 2, 148, 10, 16, 179, 245, 251, 38, 135, 180, 150, 26, 161, 168, 147, 181, 62, 42, 229, 128, 152, 148, 153, 157, 26, 60, 174, 233, 111, 103, 183, 99, 24, 99, 54, 107, 5, 129, 145, 146, 67, 80, 188, 215]);
    let x_1 = Fp::from_be_bytes([165, 169, 192, 117, 158, 35, 246, 6, 170, 160, 197, 157, 188, 205, 96, 195, 59, 177, 126, 24, 226, 134, 120, 6, 27, 26, 182, 204, 133, 65, 179, 103, 194, 182, 237, 14, 242, 21, 133, 71, 17, 146, 42, 9, 115, 96, 237, 243]);
    let x = Fp2 {
        c0: x_0,
        c1: x_1
    };

    let y_0 = Fp::from_be_bytes([76, 115, 10, 248, 96, 73, 76, 74, 89, 124, 250, 31, 94, 54, 156, 90, 231, 230, 133, 108, 170, 10, 99, 90, 187, 239, 181, 233, 110, 13, 73, 95, 7, 211, 169, 117, 240, 239, 37, 162, 0, 131, 253, 142, 126, 128, 218, 229]);
    let y_1 = Fp::from_be_bytes([173, 192, 252, 146, 223, 100, 176, 93, 24, 170, 39, 10, 43, 20, 97, 220, 134, 173, 172, 106, 59, 228, 235, 160, 121, 73, 92, 78, 201, 61, 163, 58, 231, 23, 88, 80, 164, 60, 202, 237, 11, 43, 194, 161, 99, 222, 27, 242]);
    let y = Fp2 {
        c0: y_0,
        c1: y_1
    };

    G2Projective {
        x,
        y,
        z: Fp2::one()
    }
}

pub fn g2_projective(p: G2Affine) -> G2Projective {
    let mut p_proj = G2Projective {
        x: p.x,
        y: p.y,
        z: Fp2::one()
    };

    if p_proj.infinity {
        p_proj.z = Fp2::zero();
    }

    p_proj
}

pub fn g2_double(p: G2Projective) -> G2Projective {
    let G2Projective { x: x, y: y, z: z } = p;
    let t0 = y * y;
    let z3 = t0 + t0;
    let z3 = z3 + z3;
    let z3 = z3 + z3;
    let t1 = y * z;
    let t2 = z * z;
    let t2 = t2 * g2_b3();
    let x3 = t2 * z3;
    let y3 = t0 + t2;
    let z3 = t1 * z3;
    let t1 = t2 + t2;
    let t2 = t1 + t2;
    let t0 = t0 - t2;
    let y3 = t0 * y3;
    let y3 = x3 + y3;
    let t1 = x * y;
    let x3 = t0 * t1;
    let x3 = x3 + x3;

    let tmp = G2Projective {
        x: x3,
        y: y3,
        z: z3,
    };

    if g2_is_identity(tmp) {
        g2_identity
    } else {
        tmp
    }
}

pub fn add(lhs: G2Projective, rhs: G2Projective) -> G2Projective {
    let t0 = lhs.x * rhs.x;
    let t1 = lhs.y * rhs.y;
    let t2 = lhs.z * rhs.z;
    let t3 = lhs.x + lhs.y;
    let t4 = rhs.x + rhs.y;
    let t3 = t3 * t4;
    let t4 = t0 + t1;
    let t3 = t3 - t4;
    let t4 = lhs.y + lhs.z;
    let x3 = rhs.y + rhs.z;
    let t4 = t4 * x3;
    let x3 = t1 + t2;
    let t4 = t4 - x3;
    let x3 = lhs.x + lhs.z;
    let y3 = rhs.x + rhs.z;
    let x3 = x3 * y3;
    let y3 = t0 + t2;
    let y3 = x3 - y3;
    let x3 = t0 + t0;
    let t0 = x3 + t0;
    let t2 = t2 * g2_b3();
    let z3 = t1 + t2;
    let t1 = t1 - t2;
    let y3 = y3 * g2_b3();
    let x3 = t4 * y3;
    let t2 = t3 * t1;
    let x3 = t2 - x3;
    let y3 = y3 * t0;
    let t1 = t1 * z3;
    let y3 = t1 + y3;
    let t0 = t0 * t3;
    let z3 = z3 * t4;
    let z3 = z3 + t0;

    G2Projective {
        x: x3,
        y: y3,
        z: z3,
    }
}

pub fn g2_multiply(point: G2Projective, scalar: Fr) -> G2Projective {
    let mut acc = g2_identity();
    let mut temp = point;

    let scalar_bytes = scalar.to_le_bytes();
    let bits = to_bits::<32, SCALAR_NUM_BITS>(scalar_bytes);

    for bit in bits {
        if bit == 1 as u1 {
            acc = g2_add(temp, acc);
        }
        temp = g2_double(temp);
    }
    acc
}

// 5 * P
#[test]
fn test_g1_mul() {
    let x = [
        229, 46, 85, 206, 41, 42, 4, 15, 130, 248, 168, 57, 217, 198, 212, 219, 176, 229, 152, 7, 2, 11, 168, 161, 37, 74, 96, 39, 220, 207, 69, 45, 155, 109, 177, 196, 112, 199, 165, 13, 45, 231, 205, 250, 148, 180, 107, 3
    ];

    let y = [
        160, 11, 175, 133, 228, 165, 8, 24, 36, 108, 76, 174, 14, 27, 188, 115, 15, 117, 86, 12, 187, 30, 164, 77, 104, 22, 250, 237, 161, 192, 25, 64, 115, 86, 112, 210, 225, 110, 176, 83, 255, 0, 192, 156, 228, 246, 172, 7
    ];

    let point = G1Projective::from_affine(g1_from_bytes(x, y));

    let x = [
        92, 205, 238, 245, 74, 115, 129, 163, 205, 178, 95, 166, 104, 76, 175, 67, 77, 39, 172, 14, 170, 73, 216, 45, 9, 21, 191, 198, 39, 112, 53, 222, 59, 247, 9, 152, 12, 142, 145, 132, 3, 181, 30, 231, 231, 204, 43, 3
    ];
    let y = [
        136, 77, 149, 43, 69, 134, 81, 85, 27, 162, 133, 104, 234, 165, 104, 11, 137, 216, 41, 247, 230, 199, 221, 173, 202, 52, 5, 21, 30, 223, 15, 57, 215, 103, 75, 220, 66, 138, 124, 190, 170, 88, 148, 177, 103, 132, 228, 17
    ];
    let expected = G1Projective::from_affine(g1_from_bytes(x, y));

    let mut scalar_5 = Fr::new();
    scalar_5.limbs[0] = 5;
    let actual = point.mul(scalar_5);
    assert(actual.x == expected.x);
    assert(actual.y == expected.y);
    assert(actual.z == expected.z);
}

// 2 * P == p + P
#[test]
fn test_g2_mul() {
    let two = Fr::one() + Fr::one();
    let scalar_2 = g2_multiply(g2_generator(), two);

    let g2_gen_add = g2_add(g2_generator(), g2_generator());
    assert(scalar_2.x == g2_gen_add.x);
    assert(scalar_2.y == g2_gen_add.y);
    assert(scalar_2.z == g2_gen_add.z);
}
