from py_ecc.optimized_bls12_381 import G1, G2, multiply, normalize, curve_order, add, neg, pairing, FQ12
r = curve_order

def arr(v, n): return "[" + ", ".join(str(b) for b in int(v).to_bytes(n, 'big')) + "]"
def g1a(P):
    x, y = normalize(P); return arr(x, 48), arr(y, 48)
def g2a(P):
    x, y = normalize(P)
    return arr(x.coeffs[0],48), arr(x.coeffs[1],48), arr(y.coeffs[0],48), arr(y.coeffs[1],48)

tau = 0x2f3a1c04e5b7a9d16c8e0f2b3d4a5968718293a4b5c6d7e8f90a1b2c3d4e5f60 % r
f = [4, 7, 13, 2]
def ev(p, z):
    acc = 0
    for c in reversed(p): acc = (acc * z + c) % r
    return acc
def quotient(f, x, y):
    g = list(f); g[0] = (g[0]-y) % r
    n = len(g)-1; q = [0]*n; rem = 0
    for i in range(n, -1, -1):
        if i == n: rem = g[i] % r; q[i-1] = rem
        else:
            cur = (g[i] + rem*x) % r
            if i > 0: q[i-1] = cur; rem = cur
            else: assert cur % r == 0
    return q

x = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef % r
y = ev(f, x)
C = multiply(G1, ev(f, tau))
PI = multiply(G1, ev(quotient(f, x, y), tau))
TAU_G2 = multiply(G2, tau)

A = add(add(C, neg(multiply(G1, y))), multiply(PI, x))
assert pairing(G2, A) * pairing(TAU_G2, neg(PI)) == FQ12.one()

cx, cy = g1a(C); px, py = g1a(PI)
gx0, gx1, gy0, gy1 = g2a(G2)
tx0, tx1, ty0, ty1 = g2a(TAU_G2)

# an on-curve G1 point outside the prime-order subgroup
from py_ecc.optimized_bls12_381 import b, field_modulus, FQ, is_on_curve, is_inf
def off_subgroup():
    xv = 1
    while True:
        rhs = FQ(xv)**3 + b
        s = rhs ** ((field_modulus + 1) // 4)
        if s * s == rhs:
            P = (FQ(xv), s, FQ.one())
            if is_on_curve(P, b) and not is_inf(multiply(P, r)):
                return P
        xv += 1
Pbad = off_subgroup()
bx, by = g1a(Pbad)

print(f'''// Test vectors generated with py_ecc (independent implementation).
// Polynomial f(X) = 4 + 7X + 13X^2 + 2X^3 committed under a fixed tau.
// The relation e(C - y*G1 + x*pi, G2) * e(-pi, tau*G2) == 1 is asserted natively
// in the generator before the bytes below are emitted.
use crate::serde::{{fr_from_be_bytes, g1_from_be_bytes, g2_from_be_bytes, in_subgroup}};
use crate::{{Fr, G1, VerifierKey, assert_kzg, verify_kzg}};
use noir_bigcurve::{{BigCurve, BLS12_381}};

fn commitment() -> G1 {{
    g1_from_be_bytes({cx}, {cy})
}}

fn proof() -> G1 {{
    g1_from_be_bytes({px}, {py})
}}

fn vk() -> VerifierKey {{
    VerifierKey::from_tau_g2(
        g2_from_be_bytes({gx0}, {gx1}, {gy0}, {gy1}),
        g2_from_be_bytes({tx0}, {tx1}, {ty0}, {ty1}),
    )
}}

fn eval_point() -> Fr {{
    fr_from_be_bytes({arr(x,32)})
}}

fn eval_result() -> Fr {{
    fr_from_be_bytes({arr(y,32)})
}}

// --- input validation (cheap: no pairing) ---

#[test]
fn generator_is_in_subgroup() {{
    assert(in_subgroup(BLS12_381::one()));
}}

#[test]
fn identity_is_in_subgroup() {{
    assert(in_subgroup(BLS12_381::point_at_infinity()));
}}

#[test]
fn vector_points_are_in_subgroup() {{
    assert(in_subgroup(commitment()));
    assert(in_subgroup(proof()));
}}

#[test(should_fail_with = "g1 point is not in the prime-order subgroup")]
fn rejects_point_outside_subgroup() {{
    let _ = g1_from_be_bytes({bx}, {by});
}}

#[test(should_fail)]
fn rejects_off_curve_point() {{
    // valid x, y taken from a different point: not a curve solution
    let _ = g1_from_be_bytes({cx}, {py});
}}

#[test(should_fail)]
fn rejects_noncanonical_scalar() {{
    // r itself is not a canonical scalar
    let _ = fr_from_be_bytes({arr(r,32)});
}}

// --- end-to-end verification (expensive: two Miller loops) ---

#[test]
fn verifies_valid_opening() {{
    assert_kzg(vk(), eval_point(), eval_result(), commitment(), proof());
}}

#[test]
fn rejects_wrong_evaluation() {{
    let wrong = eval_result() + Fr::one();
    assert(!verify_kzg(vk(), eval_point(), wrong, commitment(), proof()));
}}

#[test]
fn rejects_wrong_evaluation_point() {{
    let wrong = eval_point() + Fr::one();
    assert(!verify_kzg(vk(), wrong, eval_result(), commitment(), proof()));
}}

#[test]
fn rejects_tampered_proof() {{
    let tampered = proof() + BLS12_381::one();
    assert(!verify_kzg(vk(), eval_point(), eval_result(), commitment(), tampered));
}}

#[test]
fn rejects_tampered_commitment() {{
    let tampered = commitment() + BLS12_381::one();
    assert(!verify_kzg(vk(), eval_point(), eval_result(), tampered, proof()));
}}
''')
