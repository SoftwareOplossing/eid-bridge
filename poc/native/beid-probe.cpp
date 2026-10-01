// SPDX-FileCopyrightText: Let's Peppol contributors
// SPDX-License-Identifier: MIT

#include "windows-module.hpp"
#include "pkcs11.h"
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace
{
void check(const char* operation, CK_RV result)
{
    std::cout << operation << "=0x" << std::hex << result << std::dec << '\n';
    if (result != CKR_OK) throw std::runtime_error(operation);
}

struct Module
{
    HMODULE handle = nullptr;
    CK_FUNCTION_LIST_PTR functions = nullptr;
    bool initialized = false;
    ~Module()
    {
        if (initialized) functions->C_Finalize(nullptr);
        if (handle) FreeLibrary(handle);
    }
};
}

int wmain(int argc, wchar_t** argv)
{
    if (argc < 2 || argc > 3 || (argc == 3 && std::wstring(argv[2]) != L"--require-token")) {
        std::cerr << "Usage: beid-probe ABSOLUTE_DLL_PATH [--require-token]\n";
        return 2;
    }
    try {
        const std::filesystem::path path(argv[1]);
        std::wcout << L"module=" << path.native() << L'\n';
        Module module;
        module.handle = electronic_id::windows_module::loadPrivateLibrary(path);
        if (!module.handle) {
            std::cerr << "LoadLibraryExW failed; win32=" << GetLastError() << '\n';
            return 1;
        }
        std::cout << "module_loaded=true\n";
        auto getFunctions = reinterpret_cast<CK_C_GetFunctionList>(
            GetProcAddress(module.handle, "C_GetFunctionList"));
        if (!getFunctions) throw std::runtime_error("Missing C_GetFunctionList export");
        check("C_GetFunctionList", getFunctions(&module.functions));
        if (!module.functions || !module.functions->C_Initialize ||
            !module.functions->C_Finalize || !module.functions->C_GetSlotList ||
            !module.functions->C_GetTokenInfo) {
            throw std::runtime_error("Incomplete PKCS#11 function table");
        }
        check("C_Initialize", module.functions->C_Initialize(nullptr));
        module.initialized = true;

        // Slot count may change between calls when a card is inserted or removed.
        std::vector<CK_SLOT_ID> slots;
        bool enumerated = false;
        for (int attempt = 0; attempt < 3 && !enumerated; ++attempt) {
            CK_ULONG count = 0;
            check("C_GetSlotList(count)", module.functions->C_GetSlotList(CK_TRUE, nullptr, &count));
            if (count > 1024) throw std::runtime_error("Unreasonable slot count");
            if (!count) { slots.clear(); enumerated = true; break; }
            slots.resize(count);
            const auto result = module.functions->C_GetSlotList(CK_TRUE, slots.data(), &count);
            if (result == CKR_BUFFER_TOO_SMALL) continue;
            check("C_GetSlotList", result);
            if (count > slots.size()) throw std::runtime_error("Invalid returned slot count");
            slots.resize(count);
            enumerated = true;
        }
        if (!enumerated) throw std::runtime_error("Slots kept changing; retry with card inserted");
        for (const auto slot : slots) {
            CK_TOKEN_INFO info {};
            check("C_GetTokenInfo", module.functions->C_GetTokenInfo(slot, &info));
            // Deliberately omit label, serial number and identity-bearing fields.
        }
        std::cout << "tokens_present=" << slots.size() << '\n';
        const bool missingToken = argc == 3 && slots.empty();
        const auto finalizeResult = module.functions->C_Finalize(nullptr);
        module.initialized = false;
        check("C_Finalize", finalizeResult);
        return missingToken ? 3 : 0;
    } catch (const std::exception& error) {
        std::cerr << "Probe failed: " << error.what() << '\n';
        return 1;
    }
}
