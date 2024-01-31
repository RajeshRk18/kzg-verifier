use dep::bls12_381::field::prime_field::PrimeField;
use dep::bls12_381::curve::g2::G2Point;
use dep::bls12_381::curve::swcurve::{Curve, Point as G1Point};
use dep::bls12_381::curve::fp12::Fp12;
use dep::bls12_381::curve::pairing::{pair, final_exponentiation, miller_loop};
use dep::bls12_381::curve::{bls12_381, bls12_381_g2, BLS12_381, BLS12_381G2 };
use dep::std::collections::vec::Vec;

struct Polynomial {
    coeffs: Vec<PrimeField>
}

impl Polynomial {
    pub fn new() -> Self {
        let coeff_vec = Vec::new();
        Self {
            coeffs: coeff_vec
        }
    }

    pub fn from(coeffs: Vec<PrimeField>) -> Self {
        Self {
            coeffs
        }
    }

    pub fn default() -> Self {
        Polynomial::new()
    }

    pub fn new_monomial(coeff: PrimeField, degree: Field) -> Self {
        let mut padded_coeffs = Vec::new();

        for _i in 0..degree {
            padded_coeffs.push(PrimeField::zero());
        }

        padded_coeffs.push(coeff);

        Polynomial::from(padded_coeffs)
    }

    pub fn len(self: Self) -> Field {
        self.coeffs.len()
    }

    pub fn degree(self: Self) -> Field {
        self.len() - 1
    }

    pub fn leading_coefficient(self: Self) -> PrimeField {
        self.coeffs.get(self.degree())
    }

    pub fn resize(self: &mut Self, len: Field) {
        for _i in 0..len {
            self.coeffs.push(PrimeField::zero());
        }
    }

    pub fn eq(self: Self, other: Self) -> bool {
        let mut res = true;

        let mut poly1 = self;
        let mut poly2 = other;
        let poly1_len = self.len();
        let poly2_len = other.len();

        if poly1_len as u112 > poly2_len as u112 {
            poly2.resize(poly1_len - poly2_len);
        } else if poly1_len as u112 > poly2_len as u112 {
            poly1.resize(poly2_len - poly1_len);
        }

        for i in 0..poly1_len {
            res &= poly1.coeffs.get(i).eq(poly2.coeffs.get(i));
        } 

        res
    }

    pub fn add(self: Self, other: Self) -> Self {
        let mut poly1 = self;
        let mut poly2 = other;
        let poly1_len = poly1.len();
        let poly2_len = poly2.len();

        let mut new_coeffs = Vec::new();

        if poly1_len as u112 > poly2_len as u112 {
            poly2.resize(poly1_len - poly2_len);
        } else if poly1_len as u112 > poly2_len as u112 {
            poly1.resize(poly2_len - poly1_len);
        }

        for i in 0..poly1_len {
            let res = poly1.coeffs.get(i).add(poly2.coeffs.get(i));
            new_coeffs.push(res);
        }

        Polynomial::from(new_coeffs)
    }

    pub fn sub(self: Self, other: Self) -> Self {
        self.add(other.negate())
    }

    pub fn mul(self: Self, other: Self) -> Self {
        let mut poly = Polynomial::new();

        let poly1_len = self.len() as u112;
        let poly2_len = other.len() as u112;
        if poly1_len == 0 {
            poly = Polynomial::default();
        } else if poly2_len == 0 {
            poly = Polynomial::default();
        } else { 
            let res_degree = self.len() + other.len();
            let mut res_coeffs = [];

            for _i in 0..res_degree {
                res_coeffs = res_coeffs.push_back(PrimeField::zero());
            }

            for i in 0..other.degree()+1 {
                for j in 0..self.degree()+1 {
                    let mut coeff_at_index = res_coeffs[i+j];
                    let temp = coeff_at_index.add(other.coeffs.get(i).mul(self.coeffs.get(j)));
                    res_coeffs[i+j] = temp;
                }
            }
            let res_coeffs: [PrimeField] = res_coeffs;

            poly = Polynomial::from(Vec::from_slice(res_coeffs));
        }

        poly
    }

    /// Ruffini division is long division where the divisor is a binomial of the form `x - r`. Its an efficient algorithm of this setting.
    /// This can be used in the verify fn where the divisor is a binomial `x - r`
    pub fn div(self: Self, element: PrimeField) -> Self {
        let mut coeffs = Vec::new();
        let mut coeff_at_pos = self.coeffs.get(self.degree());

        for i in 0..self.degree() {
            coeffs.push(coeff_at_pos);
            coeff_at_pos = self.coeffs.get(i).add(coeff_at_pos.mul(element));
        }

        Polynomial::from(coeffs)
    }

    pub fn negate(self: Self) -> Self {
        let mut coeffs = Vec::new();

        for i in 0..self.coeffs.len() {
            coeffs.push(self.coeffs.get(i).neg());
        }

        Polynomial::from(coeffs)
    }

    pub fn sub_with_fp(self: Self, element: PrimeField) -> Self {
        self.add(Polynomial::new_monomial(element, 0).negate())
    }
}
