# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
"""Hardware check through Web eID CLI. PIN entry stays in the native UI."""

import argparse
import base64
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec, padding, rsa, utils

PAYLOAD = b"Let's Peppol eID Bridge PoC\n"
DIGEST = hashlib.sha256(PAYLOAD).digest()


def card_route(stderr):
    routes = set()
    for line in stderr.decode("utf-8", errors="replace").splitlines():
        if line.startswith("INFO: Card ") and " in reader " in line:
            name = line[len("INFO: Card "):].split(" in reader ", 1)[0].strip('"')
            if name == "Belgian eID (PKCS#11)":
                routes.add("belgian-pkcs11")
            elif name == "MS CryptoAPI electronic ID":
                routes.add("windows-cryptoapi")
            else:
                routes.add("other")
    if len(routes) != 1:
        raise RuntimeError("Card route was missing or ambiguous")
    return routes.pop()


def native_command(app, command, arguments, *, include_route=False):
    result = subprocess.run(
        [str(app), "-c", command, json.dumps(arguments)],
        capture_output=True, timeout=180, check=False,
    )
    # Do not echo native stdout/stderr: they may contain certificate/identity data.
    if result.returncode:
        raise RuntimeError(f"Native {command} failed (exit {result.returncode})")
    response = json.loads(result.stdout)
    if not isinstance(response, dict) or "error" in response:
        raise RuntimeError(f"Native {command} returned an error")
    return (response, card_route(result.stderr)) if include_route else response


def verify(certificate, digest, response):
    cert = x509.load_der_x509_certificate(base64.b64decode(certificate, validate=True))
    public_key = cert.public_key()
    algorithm = response["signatureAlgorithm"]
    signature = base64.b64decode(response["signature"], validate=True)
    if len(digest) != 32 or algorithm["hashFunction"] != "SHA-256":
        raise ValueError("Expected a SHA-256 digest and response")
    if isinstance(public_key, rsa.RSAPublicKey):
        if algorithm["cryptoAlgorithm"] != "RSA" or algorithm["paddingScheme"] != "PKCS1.5":
            raise ValueError("Unexpected RSA signature algorithm")
        public_key.verify(signature, digest, padding.PKCS1v15(), utils.Prehashed(hashes.SHA256()))
    elif isinstance(public_key, ec.EllipticCurvePublicKey):
        if algorithm["cryptoAlgorithm"] != "ECC" or algorithm["paddingScheme"] != "NONE":
            raise ValueError("Unexpected ECC signature algorithm")
        # Web eID returns fixed-width P1363 r || s; cryptography expects ASN.1 DER.
        width = (public_key.key_size + 7) // 8
        if len(signature) != 2 * width:
            raise ValueError("Unexpected ECDSA signature length")
        der = utils.encode_dss_signature(
            int.from_bytes(signature[:width], "big"), int.from_bytes(signature[width:], "big")
        )
        public_key.verify(der, digest, ec.ECDSA(utils.Prehashed(hashes.SHA256())))
    else:
        raise ValueError("Unsupported certificate public key")
    return cert.fingerprint(hashes.SHA256()).hex()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path, help="Absolute path to web-eid.exe")
    parser.add_argument("--origin", required=True, help="Development HTTPS origin shown in native UI")
    parser.add_argument("--route-only", action="store_true",
                        help="Report the selected card backend without signing or printing certificate data")
    args = parser.parse_args()
    if not args.app.is_absolute() or not args.app.is_file():
        parser.error("--app must name an existing absolute executable path")
    if args.route_only:
        print("Checking card route; no PIN is needed.", file=sys.stderr)
        certificate_response, route = native_command(
            args.app, "get-signing-certificate", {"origin": args.origin}, include_route=True)
        if not certificate_response.get("certificate"):
            raise RuntimeError("No signing certificate returned")
        print(json.dumps({"card_route": route, "certificate_retrieved": True}))
        return
    print("Retrieve the signing certificate, then approve the PoC signature in the native UI.", file=sys.stderr)
    certificate_response = native_command(args.app, "get-signing-certificate", {"origin": args.origin})
    if not any(a.get("hashFunction") == "SHA-256"
               for a in certificate_response["supportedSignatureAlgorithms"]):
        raise RuntimeError("Card does not advertise SHA-256 signing")
    certificate = certificate_response["certificate"]
    response = native_command(args.app, "sign", {
        "origin": args.origin, "certificate": certificate,
        "hash": base64.b64encode(DIGEST).decode(), "hashFunction": "SHA-256",
    })
    fingerprint = verify(certificate, DIGEST, response)
    print(json.dumps({"signature_verified": True, "digest_sha256": DIGEST.hex(),
                      "certificate_sha256": fingerprint,
                      "signature_algorithm": response["signatureAlgorithm"]}, indent=2))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Avoid exception payloads containing native output or certificates.
        print(f"Hardware check failed ({type(error).__name__}); no successful result recorded.", file=sys.stderr)
        sys.exit(1)
