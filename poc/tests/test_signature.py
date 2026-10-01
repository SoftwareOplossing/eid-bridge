# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT

import base64
from datetime import datetime, timedelta, timezone
import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

from cryptography import x509
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, padding, rsa, utils
from cryptography.x509.oid import NameOID

spec = importlib.util.spec_from_file_location("check_signature", Path(__file__).parents[1] / "scripts/check-signature.py")
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


def certificate(key):
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Synthetic PoC test")])
    now = datetime.now(timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
            .public_key(key.public_key()).serial_number(1)
            .not_valid_before(now).not_valid_after(now + timedelta(days=1))
            .sign(key, hashes.SHA256()))
    return base64.b64encode(cert.public_bytes(serialization.Encoding.DER)).decode()


def response(key, digest=check.DIGEST):
    if isinstance(key, rsa.RSAPrivateKey):
        signature = key.sign(digest, padding.PKCS1v15(), utils.Prehashed(hashes.SHA256()))
        algorithm = {"cryptoAlgorithm": "RSA", "paddingScheme": "PKCS1.5", "hashFunction": "SHA-256"}
    else:
        der = key.sign(digest, ec.ECDSA(utils.Prehashed(hashes.SHA256())))
        r, s = utils.decode_dss_signature(der)
        width = (key.key_size + 7) // 8
        signature = r.to_bytes(width, "big") + s.to_bytes(width, "big")
        algorithm = {"cryptoAlgorithm": "ECC", "paddingScheme": "NONE", "hashFunction": "SHA-256"}
    return {"signature": base64.b64encode(signature).decode(), "signatureAlgorithm": algorithm}


class SignatureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.keys = [rsa.generate_private_key(public_exponent=65537, key_size=2048),
                    ec.generate_private_key(ec.SECP384R1())]

    def test_rsa_and_ecc_signatures_verify(self):
        for key in self.keys:
            with self.subTest(key=type(key).__name__):
                self.assertEqual(len(check.verify(certificate(key), check.DIGEST, response(key))), 64)

    def test_changed_digest_rejected(self):
        for key in self.keys:
            with self.subTest(key=type(key).__name__), self.assertRaises(InvalidSignature):
                check.verify(certificate(key), bytes(32), response(key))

    def test_changed_signature_rejected(self):
        for key in self.keys:
            signed = response(key)
            raw = bytearray(base64.b64decode(signed["signature"]))
            raw[-1] ^= 1
            signed["signature"] = base64.b64encode(raw).decode()
            with self.subTest(key=type(key).__name__), self.assertRaises(InvalidSignature):
                check.verify(certificate(key), check.DIGEST, signed)

    def test_substituted_certificate_rejected(self):
        other_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        with self.assertRaises(InvalidSignature):
            check.verify(certificate(other_key), check.DIGEST, response(self.keys[0]))

    def test_wrong_algorithm_rejected(self):
        signed = response(self.keys[0])
        signed["signatureAlgorithm"]["hashFunction"] = "SHA-384"
        with self.assertRaises(ValueError):
            check.verify(certificate(self.keys[0]), check.DIGEST, signed)

    def test_truncated_ecc_rejected(self):
        signed = response(self.keys[1])
        signed["signature"] = base64.b64encode(b"short").decode()
        with self.assertRaises(ValueError):
            check.verify(certificate(self.keys[1]), check.DIGEST, signed)

    @patch.object(check.subprocess, "run")
    def test_native_error_does_not_disclose_output(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, b'{"error":{"message":"private-data"}}', b"private-data")
        with self.assertRaises(RuntimeError) as error:
            check.native_command("app.exe", "sign", {})
        self.assertNotIn("private-data", str(error.exception))
        self.assertFalse(run.call_args.kwargs.get("shell", False))

    @patch.object(check.subprocess, "run", side_effect=subprocess.TimeoutExpired("app.exe", 180))
    def test_timeout_does_not_pass(self, run):
        with self.assertRaises(subprocess.TimeoutExpired):
            check.native_command("app.exe", "sign", {})


if __name__ == "__main__":
    unittest.main()
