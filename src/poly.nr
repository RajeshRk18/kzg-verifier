use dep::bls12_381::field::prime_field::PrimeField;
use dep::bls12_381::curve::g2::G2Point;
use dep::bls12_381::curve::swcurve::{Curve, Point as G1Point};
use dep::bls12_381::curve::fp12::Fp12;
use dep::bls12_381::curve::pairing::{pair, final_exponentiation, miller_loop};
use dep::bls12_381::curve::{bls12_381, bls12_381_g2, BLS12_381, BLS12_381G2 };
use dep::std::collections::vec::Vec;

/// This wont work if the polynomial is of size larger than MAX_POLY_SIZE as the loop is unbounded and the compiler expects it to be bounded in compole time.
/// This should not impact the verifier api because verifier does not need to evaluate any polynomial.

/// If we want to work with polynomials of size larger than MAX_POLY_SIZE, maybe we can do the following:
///           - sub divide a polynomial of size MAX_SUB_POLY_SIZE and iterating upto `MAX_ITERATIONS` for ops. 
///           - With this trick, we can operate over polynomials upto degree MAX_SUB_POLY_SIZE * MAX_ITERATIONS - 1.
/// NOTE: This trick will add lots of complexities to the code.

/// As the loop needs to be bounded, we restrict the polynomial size. This is highly inefficient and generates more constraints than needed 
/// if the polynomial is less than MAX_POLY_SIZE.
global MAX_POLY_SIZE: u112 = 1000000000;

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

    // creates a new monomial of given degree
    pub fn new_monomial(coeff: PrimeField, degree: Field) -> Self {
        let mut padded_coeffs = Vec::new();

        for _i in 0..degree {
            padded_coeffs.push(PrimeField::zero());
        }

        padded_coeffs.push(coeff);

        Polynomial::from(padded_coeffs)
    }

    // outputs the polynomial size which is usually highest degree + 1
    pub fn len(self: Self) -> Field {
        self.coeffs.len()
    }

    // outputs the highest degree of a polynomial
    pub fn degree(self: Self) -> Field {
        self.len() - 1
    }

    // outputs the leading coefficient
    pub fn leading_coefficient(self: Self) -> PrimeField {
        self.coeffs.get(self.degree())
    }

    // resizes the poly to MAX_POLY_SIZE
    pub fn resize(self: &mut Self) {
        for _i in 0..MAX_POLY_SIZE {
            self.coeffs.push(PrimeField::zero());
        }
    }

    // checks if two polynomials are equal
    pub fn eq(self: Self, other: Self) -> bool {
        let mut res = true;

        let mut poly1 = self;
        let mut poly2 = other;

        poly1.resize();
        poly2.resize();

        for i in 0..MAX_POLY_SIZE {
            res &= poly1.coeffs.get(i as Field).eq(poly2.coeffs.get(i as Field));
        }

        res
    }

    // adds two polynomials
    pub fn add(self: Self, other: Self) -> Self {
        let mut poly1 = self;
        let mut poly2 = other;

        let mut new_coeffs = Vec::new();

        poly1.resize();
        poly2.resize();

        for i in 0..MAX_POLY_SIZE {
            let res = poly1.coeffs.get(i as Field).add(poly2.coeffs.get(i as Field));
            new_coeffs.push(res);
        }

        Polynomial::from(new_coeffs)
    }

    // subtracts two polnomials
    pub fn sub(self: Self, other: Self) -> Self {
        self.add(other.negate())
    }

    // multiplies two polynomials
    pub fn mul(self: Self, other: Self) -> Self {
        let mut poly = Polynomial::new();

        let poly1_len = self.len() as u112;
        let poly2_len = other.len() as u112;

        if poly1_len == 0 {
            poly = Polynomial::default();
        } else if poly2_len == 0 {
            poly = Polynomial::default();
        } else {
            // this is done to resize the resulting polynomial. As, both input polynomials are MAX_POLY_SIZE or lower,
            // we instantiate the resulting polynomial with MAX_POLY_SIZE * 2 to avoid out of index bounds. 
            let max_degree_times_2 = MAX_POLY_SIZE * 2;
            let mut res_coeffs = [];

            for _i in 0..max_degree_times_2 {
                res_coeffs = res_coeffs.push_back(PrimeField::zero());
            }

            for i in 0..MAX_POLY_SIZE {
                for j in 0..MAX_POLY_SIZE {
                    let mut coeff_at_index = res_coeffs[i+j];
                    let temp = coeff_at_index.add(other.coeffs.get(i as Field).mul(self.coeffs.get(j as Field)));
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

        let poly_len = self.len();

        for i in 0..MAX_POLY_SIZE {
            if poly_len as u112 < MAX_POLY_SIZE {
                coeffs.push(coeff_at_pos);
                coeff_at_pos = self.coeffs.get(i as Field).add(coeff_at_pos.mul(element));
            }
        }

        Polynomial::from(coeffs)
    }

    // negates a polynomial
    pub fn negate(self: Self) -> Self {
        let mut coeffs = Vec::new();
        let poly_len = self.len();

        for i in 0..MAX_POLY_SIZE {
            if poly_len as u112 < MAX_POLY_SIZE {
                coeffs.push(self.coeffs.get(i as Field).neg());
            }
        }

        Polynomial::from(coeffs)
    }

    // subtract the 0th degree coefficient from a field element
    pub fn sub_with_fp(self: Self, element: PrimeField) -> Self {
        self.add(Polynomial::new_monomial(element, 0).negate())
    }
}

#[test]
fn test_poly1() {
    let eq1 = Polynomial::new_monomial(PrimeField::zero(), 0);
    let eq2 = Polynomial::new_monomial(PrimeField::one(), 0);

    assert(eq1.mul(eq2).eq(eq1));
}

#[test]
fn test_poly2() {
    let eq1 = Polynomial::new_monomial(PrimeField::from_u56(5), 0);
    let eq2 = Polynomial::new_monomial(PrimeField::from_u56(6), 0);
    let eq3 = Polynomial::new_monomial(PrimeField::from_u56(30), 0);

    assert(eq1.mul(eq2).eq(eq3));
}

#[test]
fn test_poly3() {
    let mut coeff = Vec::new();
    coeff.push(PrimeField::from_u56(7));

    let eq1 = Polynomial::from(coeff);
    let eq2 = Polynomial::new_monomial(PrimeField::from_u56(6), 0);
    let eq3 = Polynomial::new_monomial(PrimeField::from_u56(13), 0);

    assert(eq1.add(eq2).eq(eq3));
}

#[test]
fn test_resize() {
    let mut poly = Polynomial::new_monomial(PrimeField::from_u56(45), 6);
    let len = poly.len();
    poly.resize();

    assert(poly.len() as u112 == len as u112 + MAX_POLY_SIZE);
}
