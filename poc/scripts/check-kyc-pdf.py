# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
"""Offline PDF signature integrity check. Outputs no contract or signer data."""

import argparse
import json
import logging
from pathlib import Path
import sys

# Validator diagnostics may contain certificate subjects or document details.
logging.disable(logging.CRITICAL)

from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.pdf_utils.misc import PdfStrictReadError
from pyhanko.sign.validation import validate_pdf_signature
from pyhanko.sign.validation.status import SignatureCoverageLevel
from pyhanko_certvalidator import ValidationContext


XREF_REUSE_ERROR = 'XRef stream objects must not be clobbered in strict mode.'


def _check_document(document, strict):
    reader = PdfFileReader(document, strict=strict)
    # The library's xref reuse restriction protects encryption/cache semantics.
    # The known unencrypted KYC case can use its compatibility reader.
    if not strict and reader.encrypted:
        raise ValueError('Encrypted PDFs are unsupported in xref compatibility mode.')
    results = []
    for signature in reader.embedded_regular_signatures:
        # No OS trust fallback, network fetching, or trusted-time assertion.
        # Only the integrity/coverage fields are used from this result.
        context = ValidationContext(
            trust_roots=[], allow_fetching=False, revocation_mode='soft-fail')
        status = validate_pdf_signature(
            signature, signer_validation_context=context,
            ts_validation_context=context, skip_diff=True)
        results.append({
            'signed_bytes_intact': bool(status.intact),
            'signature_cryptographically_valid': bool(status.valid),
            'whole_file_covered': status.coverage == SignatureCoverageLevel.ENTIRE_FILE,
        })
    return {
        'pdf_parse_mode': 'strict' if strict else 'xref_compatibility',
        'signature_count': len(results),
        'signatures': results,
        # This narrowly expects one complete KYC signature, with no later updates.
        # Legitimate extra signatures/timestamps also require separate review.
        'integrity_check_passed': len(results) == 1 and all(results[0].values()),
        'certificate_trust_verified': False,
        'revocation_checked': False,
        'expected_document_and_account_verified': False,
    }


def check_pdf(path):
    with Path(path).open('rb') as document:
        try:
            return _check_document(document, strict=True)
        except PdfStrictReadError as error:
            if str(error) != XREF_REUSE_ERROR:
                raise
            # Re-read the original bytes; never repair or rewrite a signed PDF.
            document.seek(0)
            report = _check_document(document, strict=False)
            report['parser_issue'] = 'xref_stream_object_reused'
            return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pdf', type=Path, help='Downloaded signed KYC PDF, kept locally')
    args = parser.parse_args(argv)
    try:
        report = check_pdf(args.pdf)
    except Exception as error:
        # Never print an exception payload, filename, certificate or PDF content.
        report = {'integrity_check_passed': False,
                  'error': f'PDF validation failed ({type(error).__name__})'}
        if isinstance(error, PdfStrictReadError):
            # Classify known parser failures without disclosing their payload.
            report['parser_issue'] = (
                'xref_stream_object_reused'
                if str(error) == XREF_REUSE_ERROR
                else 'strict_pdf_structure_rejected')
    print(json.dumps(report, indent=2))
    return 0 if report['integrity_check_passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
