# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT

from datetime import datetime, timedelta, timezone
import importlib.util
from io import BytesIO, StringIO
from pathlib import Path
import socket
import tempfile
import unittest
from unittest.mock import patch

from asn1crypto import keys, x509 as asn1_x509
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
from pyhanko.pdf_utils import generic
from pyhanko.pdf_utils.incremental_writer import IncrementalPdfFileWriter
from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.pdf_utils.writer import PdfFileWriter, PageObject
from pyhanko.sign import signers
from pyhanko_certvalidator.registry import SimpleCertificateStore

spec = importlib.util.spec_from_file_location(
    'check_kyc_pdf', Path(__file__).parents[1] / 'scripts/check-kyc-pdf.py')
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


class PdfCheckTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        subject = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'Synthetic private signer')])
        now = datetime.now(timezone.utc)
        cert = (x509.CertificateBuilder().subject_name(subject).issuer_name(subject)
                .public_key(key.public_key()).serial_number(1)
                .not_valid_before(now - timedelta(days=1)).not_valid_after(now + timedelta(days=1))
                .add_extension(x509.KeyUsage(True, True, False, False, False, False, False, False, False), critical=True)
                .sign(key, hashes.SHA256()))
        signer = signers.SimpleSigner(
            signing_cert=asn1_x509.Certificate.load(cert.public_bytes(serialization.Encoding.DER)),
            signing_key=keys.PrivateKeyInfo.load(key.private_bytes(
                serialization.Encoding.DER, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())),
            cert_registry=SimpleCertificateStore())
        writer = PdfFileWriter()
        content = writer.add_object(generic.StreamObject(stream_data=b'0 0 m 10 10 l S'))
        writer.insert_page(PageObject(content, (0, 0, 300, 300)))
        unsigned = BytesIO()
        writer.write(unsigned)
        cls.unsigned = unsigned.getvalue()
        signed = BytesIO()
        signers.sign_pdf(IncrementalPdfFileWriter(BytesIO(cls.unsigned)),
                         signers.PdfSignatureMetadata(field_name='KYC'), signer=signer, output=signed)
        cls.signed = signed.getvalue()

    def check_bytes(self, data):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'contract-private.pdf'
            path.write_bytes(data)
            # Windows asyncio uses a local socket pair for its event loop.
            # Block external connections while allowing that internal plumbing.
            connect = socket.socket.connect
            def offline_connect(sock, address):
                if address[0] not in ('127.0.0.1', '::1'):
                    raise AssertionError('External network access')
                return connect(sock, address)
            with patch.object(socket.socket, 'connect', offline_connect):
                return check.check_pdf(path)

    def test_intact_pdf_passes_without_claiming_trust(self):
        result = self.check_bytes(self.signed)
        self.assertTrue(result['integrity_check_passed'])
        self.assertFalse(result['certificate_trust_verified'])
        self.assertFalse(result['revocation_checked'])
        self.assertFalse(result['expected_document_and_account_verified'])

    def test_unsigned_pdf_fails(self):
        result = self.check_bytes(self.unsigned)
        self.assertFalse(result['integrity_check_passed'])
        self.assertEqual(result['signature_count'], 0)

    def test_changed_signed_bytes_fail(self):
        changed = self.signed.replace(b'/MediaBox [ 0 0 300 300 ]', b'/MediaBox [ 0 0 301 300 ]', 1)
        self.assertNotEqual(changed, self.signed)
        self.assertFalse(self.check_bytes(changed)['integrity_check_passed'])

    def test_incremental_change_fails_whole_file_coverage(self):
        writer = IncrementalPdfFileWriter(BytesIO(self.signed))
        writer.root['/TestChange'] = generic.TextStringObject('Changed after signing')
        writer.update_root()
        changed = BytesIO()
        writer.write(changed)
        result = self.check_bytes(changed.getvalue())
        self.assertTrue(result['signatures'][0]['signature_cryptographically_valid'])
        self.assertFalse(result['signatures'][0]['whole_file_covered'])
        self.assertFalse(result['integrity_check_passed'])

    def test_altered_cms_signature_fails(self):
        signature = PdfFileReader(BytesIO(self.signed)).embedded_regular_signatures[0]
        encoded = signature.signer_info['signature'].native.hex().encode('ascii')
        if encoded not in self.signed:
            encoded = encoded.upper()
        position = self.signed.index(encoded)
        replacement = b'0' if self.signed[position:position + 1] != b'0' else b'1'
        changed = self.signed[:position] + replacement + self.signed[position + 1:]
        result = self.check_bytes(changed)
        self.assertTrue(result['signatures'][0]['signed_bytes_intact'])
        self.assertFalse(result['signatures'][0]['signature_cryptographically_valid'])
        self.assertFalse(result['integrity_check_passed'])

    def test_errors_do_not_disclose_payload(self):
        with patch.object(check, 'check_pdf', side_effect=ValueError('Secret identity / contract')):
            with patch('sys.stdout', new_callable=StringIO) as output:
                self.assertEqual(check.main(['private-path.pdf']), 1)
                self.assertNotIn('Secret identity', output.getvalue())
                self.assertNotIn('private-path', output.getvalue())


if __name__ == '__main__':
    unittest.main()
