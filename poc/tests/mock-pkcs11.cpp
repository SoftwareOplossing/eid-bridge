// SPDX-FileCopyrightText: Let's Peppol contributors
// SPDX-License-Identifier: MIT
#define CRYPTOKI_EXPORTS
#include "pkcs11.h"

namespace
{
CK_RV initialize(CK_VOID_PTR) { return CKR_OK; }
CK_RV finalize(CK_VOID_PTR) { return CKR_OK; }
CK_RV slots(CK_BBOOL, CK_SLOT_ID_PTR, CK_ULONG_PTR count)
{
    *count = 0;
    return CKR_OK;
}
CK_RV token(CK_SLOT_ID, CK_TOKEN_INFO_PTR) { return CKR_TOKEN_NOT_PRESENT; }
}

extern "C" CK_RV C_GetFunctionList(CK_FUNCTION_LIST_PTR_PTR output)
{
    static CK_FUNCTION_LIST functions {};
    functions.version = {2, 20};
    functions.C_Initialize = initialize;
    functions.C_Finalize = finalize;
    functions.C_GetSlotList = slots;
    functions.C_GetTokenInfo = token;
    *output = &functions;
    return CKR_OK;
}
