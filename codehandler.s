/*********************************************************************************
*                               Author: Mewtality                                *
*                            File Name: codehandler.s                            *
*                          Last Updated: March 24, 2024                          *
*                              Source Language: asm                              *
*********************************************************************************/

.equiv "CONTROLLER_STATUS_BUFFERS", 0x10014980 # 0x480 (1152) bytes
.equiv "LIB_LOADER", 0x10014E00 # 0xFC (252) bytes
.equiv "MISCELLANEOUS", 0x10014F00

# ? Syscalls
.equiv "SC0x25_KernelCopyData", 0x2500

# ! TCP Gecko Specifics. WARNING: VALUES MUST BE SAME PROVIDED BY TCP GECKO.
.equiv "CODE_HANDLER_INSTALL_ADDRESS", 0x010F4000
.equiv "CODE_LIST_START_ADDRESS", 0x01133000
.equiv "CODE_HANDLER_ENABLED_ADDRESS", 0x10014EFC

.equiv "MEM_BASE", 0x00800000
.equiv "OS_SPECIFICS", "MEM_BASE" + 0x1500

.equiv "addr_OSDynLoad_Acquire", "OS_SPECIFICS" + 0x0
.equiv "addr_OSDynLoad_FindExport", "OS_SPECIFICS" + 0x4
.equiv "OS_DYNLOAD_OK", 0
.equiv "OS_DYNLOAD_OUT_OF_MEMORY", 0xBAD10002
.equiv "OS_DYNLOAD_INVALID_NOTIFY_PTR", 0xBAD1000E
.equiv "OS_DYNLOAD_INVALID_MODULE_NAME_PTR", 0xBAD1000F
.equiv "OS_DYNLOAD_INVALID_MODULE_NAME", 0xBAD10010
.equiv "OS_DYNLOAD_INVALID_ACQUIRE_PTR", 0xBAD10011
.equiv "OS_DYNLOAD_EMPTY_MODULE_NAME", 0xBAD10012
.equiv "OS_DYNLOAD_INVALID_ALLOCATOR_PTR", 0xBAD10017
.equiv "OS_DYNLOAD_OUT_OF_SYSTEM_MEMORY", 0xBAD1002F
.equiv "OS_DYNLOAD_TLS_ALLOCATOR_LOCKED", 0xBAD10031
.equiv "OS_DYNLOAD_MODULE_NOT_FOUND", 0xFFFFFFFA

/*.equiv "addr_OSTitle_main_entry", "OS_SPECIFICS" + 0x8
.equiv "addr_KernSyscallTbl1", "OS_SPECIFICS" + 0xC
.equiv "addr_KernSyscallTbl2", "OS_SPECIFICS" + 0x10
.equiv "addr_KernSyscallTbl3", "OS_SPECIFICS" + 0x14
.equiv "addr_KernSyscallTbl4", "OS_SPECIFICS" + 0x18
.equiv "addr_KernSyscallTbl5", "OS_SPECIFICS" + 0x1C*/

# ? Code Handler Specifics.
.equiv "CODE_LIST_LENGTH", 0xA600
.equiv "CODE_LIST_END_ADDRESS", "CODE_LIST_START_ADDRESS" + "CODE_LIST_LENGTH"

.equiv "OSFatal_Ptr", "LIB_LOADER" + 0x0
.equiv "OSEffectiveToPhysical_Ptr", "LIB_LOADER" + 0x4
.equiv "DCFlushRange_Ptr", "LIB_LOADER" + 0x8
.equiv "OSBlockSet_Ptr", "LIB_LOADER" + 0xC
.equiv "memcpy_Ptr", "LIB_LOADER" + 0x10
.equiv "OSIsAddressValid_Ptr", "LIB_LOADER" + 0x14

.equiv "OSScreenInit_Ptr", "LIB_LOADER" + 0x18
.equiv "OSScreenGetBufferSizeEx_Ptr", "LIB_LOADER" + 0x1C
.equiv "OSScreenSetBufferEx_Ptr", "LIB_LOADER" + 0x20
.equiv "OSScreenEnableEx_Ptr", "LIB_LOADER" + 0x24
.equiv "OSScreenClearBufferEx_Ptr", "LIB_LOADER" + 0x28
.equiv "OSScreenPutFontEx_Ptr", "LIB_LOADER" + 0x2C
.equiv "OSScreenFlipBuffersEx_Ptr", "LIB_LOADER" + 0x30
.equiv "SCREEN_TV", 0
.equiv "SCREEN_DRC", 1

.equiv "VPADInit_Ptr", "LIB_LOADER" + 0x34
.equiv "VPADRead_Ptr", "LIB_LOADER" + 0x38
.equiv "VPAD_READ_SUCCESS", 0
.equiv "VPAD_READ_NO_SAMPLES", -1
.equiv "VPAD_READ_INVALID_CONTROLLER", -2
.equiv "VPAD_READ_BUSY", -4
.equiv "VPAD_READ_UNINITIALIZED", -5

.equiv "WPADInit_Ptr", "LIB_LOADER" + 0x3C
.equiv "KPADInit_Ptr", "LIB_LOADER" + 0x40
.equiv "KPADReadEx_Ptr", "LIB_LOADER" + 0x44
.equiv "KPAD_ERROR_OK", 0
.equiv "KPAD_ERROR_NO_SAMPLES", -1
.equiv "KPAD_ERROR_INVALID_CONTROLLER", -2
.equiv "KPAD_ERROR_WPAD_UNINIT", -3
.equiv "KPAD_ERROR_BUSY", -4
.equiv "KPAD_ERROR_UNINITIALIZED", -5

.equiv "AVMGetDRCScanMode_Ptr", "LIB_LOADER" + 0x48
.equiv "DCUpdate_Ptr", "LIB_LOADER" + 0x4C

.equiv "addr_MEMAllocFromDefaultHeapEx", "LIB_LOADER" + 0x50
.equiv "addr_MEMFreeToDefaultHeap", "LIB_LOADER" + 0x54

.equiv "CODE_HANDLER_FUNCTION_POINTERS_FLAG", "MISCELLANEOUS" + 0x0 # 2 bytes
.equiv "CODE_HANDLER_CLEAR_FLAG", "MISCELLANEOUS" + 0x2 # 2 bytes
.equiv "CODE_HANDLER_CONDITIONAL_FLAG", "MISCELLANEOUS" + 0x4 # 4 bytes
.equiv "CODE_HANDLER_COMPUTED_POINTER", "MISCELLANEOUS" + 0x8 # 4 bytes
.equiv "CODE_HANDLER_0x0C_CODETYPE_POINTER", "MISCELLANEOUS" + 0xC # 4 bytes
.equiv "CODE_HANDLER_0x80_CODETYPE_FLAG", "MISCELLANEOUS" + 0x10 # 4 bytes
.equiv "CODE_HANDLER_PSEUDO_REGISTERS", "MISCELLANEOUS" + 0x14 # 0x40 (64) bytes
.equiv "CODE_HANDLER_RESERVED_DATA", "MISCELLANEOUS" + 0x54 # "CODE_LIST_LENGTH" bytes

# ? Common Macros.
.macro SET_ADDR reg, addr
	lis \reg, \addr@h
	ori \reg, \reg, \addr@l
.endm

.macro SET_SYMBOL_ADDR reg, symbol
	SET_ADDR \reg, ("CODE_HANDLER_INSTALL_ADDRESS" + (\symbol - codehandler))
.endm

.macro FLUSH_DATA_BLOCK reg
	li r0, 0 # Assume no offset.
	dcbf 0, \reg
	sync
.endm

.macro ROUND_UP_TO_ALIGNED reg
	addi \reg, \reg, 0x3
	rlwinm \reg, \reg, 0, 0, 29
.endm

.macro OS_ACQUIRE libraryNameLoc
	SET_SYMBOL_ADDR r3, \libraryNameLoc

	addi r4, r1, 0x8 # Assume output is in the stack.
	bl OSDynLoad_Acquire
.endm

.macro OS_FIND_EXPORT symbolNameLoc, outputAddr
	lwz r3, 0x8 (r1) # Assume module has been acquired.
	li r4, 0 # Assume function export.

	SET_SYMBOL_ADDR r5, \symbolNameLoc

	SET_ADDR r6, \outputAddr

	bl OSDynLoad_FindExport
	cmpwi r3, "OS_DYNLOAD_OK"
	bnel OSFatal_ModuleLoadFailure
.endm

.macro GOTO_EXPORT_FUNC outputAddr
	lis r11, \outputAddr@ha
	lwz r11, \outputAddr@l (r11)
	mtctr r11
	bctr
.endm

/**========================================================================
 **                              codehandler
 *?  Sets specific register values and begins execution of the codehandler.
 *?  This function reloads on each title launch.
 *========================================================================**/
codehandler:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0x14 (r1)
	stw r31, 0x10 (r1)
	stw r30, 0xC (r1)

	lis r12, "CODE_HANDLER_FUNCTION_POINTERS_FLAG"@ha
	lhz r5, "CODE_HANDLER_FUNCTION_POINTERS_FLAG"@l (r12)
	subic. r5, r5, 0x1
	bge+ ExecuteCodeHandler

	sth r5, "CODE_HANDLER_FUNCTION_POINTERS_FLAG"@l (r12)

	bl InitOSFunctionPointers
	bl InitVPadFunctionPointers
	bl InitPadScoreFunctionPointers
	bl InitMiscFunctionPointers

ExecuteCodeHandler:
	SET_ADDR r6, "CODE_LIST_START_ADDRESS" # Required register to find the start of the code list.

	SET_ADDR r7, "CODE_LIST_END_ADDRESS" # Required register to find the end of the code list.

	lis r12, "CODE_HANDLER_CLEAR_FLAG"@ha
	lhz r8, "CODE_HANDLER_CLEAR_FLAG"@l (r12)

	SET_ADDR r9, "CODE_HANDLER_ENABLED_ADDRESS" # Required register to know whether the code list was retrieved.

	li r10, 0

	lwz r11, 0 (r9)
	cmpw r11, r10
	beq _clear

	sth r10, "CODE_HANDLER_CLEAR_FLAG"@l (r12)

	mr r31, r6
	mr r30, r7
	bl UpdateControllerBuffers

	mr r3, r31
	mr r4, r30
	bl DecodeList

	b _exit

_clear:
	subic. r8, r8, 0x1
	bge+ _exit

	sth r8, "CODE_HANDLER_CLEAR_FLAG"@l (r12)
	bl DecodeListClear

_exit:
	lwz r30, 0xC (r1)
	lwz r31, 0x10 (r1)
	lwz r0, 0x18 (r1)
	mtlr r0
	addi r1, r1, 0x14
	blr

/**========================================================================
 **                         InitOSFunctionPointers
 *?  Initializes various coreinit function pointers used by the
 *?  code handler.
 *========================================================================**/
InitOSFunctionPointers:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0xC (r1)

	OS_ACQUIRE "coreinit_ascii"

	lwz r3, 0x8 (r1)
	li r4, 0
	SET_SYMBOL_ADDR r5, "OSFatal_ascii"
	SET_ADDR r6, "OSFatal_Ptr"
	bl OSDynLoad_FindExport

	OS_FIND_EXPORT "OSIsAddressValid_ascii", "OSIsAddressValid_Ptr"

	OS_FIND_EXPORT "memcpy_ascii", "memcpy_Ptr"

	OS_FIND_EXPORT "OSBlockSet_ascii", "OSBlockSet_Ptr"

	OS_FIND_EXPORT "DCFlushRange_ascii", "DCFlushRange_Ptr"

	OS_FIND_EXPORT "OSEffectiveToPhysical_ascii", "OSEffectiveToPhysical_Ptr"

	OS_FIND_EXPORT "OSScreenInit_ascii", "OSScreenInit_Ptr"

	OS_FIND_EXPORT "OSScreenGetBufferSizeEx_ascii", "OSScreenGetBufferSizeEx_Ptr"

	OS_FIND_EXPORT "OSScreenSetBufferEx_ascii", "OSScreenSetBufferEx_Ptr"

	OS_FIND_EXPORT "OSScreenEnableEx_ascii", "OSScreenEnableEx_Ptr"

	OS_FIND_EXPORT "OSScreenClearBufferEx_ascii", "OSScreenClearBufferEx_Ptr"

	OS_FIND_EXPORT "OSScreenPutFontEx_ascii", "OSScreenPutFontEx_Ptr"

	OS_FIND_EXPORT "OSScreenFlipBuffersEx_ascii", "OSScreenFlipBuffersEx_Ptr"

	lwz r3, 0x8 (r1)
	li r4, 1
	SET_SYMBOL_ADDR r5, "MEMAllocFromDefaultHeapEx_ascii"
	SET_ADDR r6, "addr_MEMAllocFromDefaultHeapEx"
	bl OSDynLoad_FindExport
	cmpwi r3, "OS_DYNLOAD_OK"
	bnel OSFatal_ModuleLoadFailure

	lwz r3, 0x8 (r1)
	li r4, 1
	SET_SYMBOL_ADDR r5, "MEMFreeToDefaultHeap_ascii"
	SET_ADDR r6, "addr_MEMFreeToDefaultHeap"
	bl OSDynLoad_FindExport
	cmpwi r3, "OS_DYNLOAD_OK"
	bnel OSFatal_ModuleLoadFailure

	lwz r0, 0x10 (r1)
	mtlr r0
	addi r1, r1, 0xC
	blr

/**========================================================================
 **                        InitVPadFunctionPointers
 *?  Initializes various vpad function pointers used by the code handler.
 *========================================================================**/
InitVPadFunctionPointers:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0xC (r1)

	OS_ACQUIRE "vpad_ascii"

	OS_FIND_EXPORT "VPADInit_ascii", "VPADInit_Ptr"

	OS_FIND_EXPORT "VPADRead_ascii", "VPADRead_Ptr"

	lwz r0, 0x10 (r1)
	mtlr r0
	addi r1, r1, 0xC
	blr

/**========================================================================
 **                      InitPadScoreFunctionPointers
 *?  Initializes various PadScore function pointers used by the
 *?  code handler.
 *========================================================================**/
InitPadScoreFunctionPointers:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0xC (r1)

	OS_ACQUIRE "padscore_ascii"

	OS_FIND_EXPORT "KPADInit_ascii", "KPADInit_Ptr"

	OS_FIND_EXPORT "WPADInit_ascii", "WPADInit_Ptr"

	OS_FIND_EXPORT "KPADReadEx_ascii", "KPADReadEx_Ptr"

	lwz r0, 0x10 (r1)
	mtlr r0
	addi r1, r1, 0xC
	blr

/**========================================================================
 **                        InitMiscFunctionPointers
 *?  Initializes various miscellaneous function pointers used by the
 *?  code handler.
 *========================================================================**/
InitMiscFunctionPointers:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0xC (r1)

	OS_ACQUIRE "avm_ascii"

	OS_FIND_EXPORT "AVMGetDRCScanMode_ascii", "AVMGetDRCScanMode_Ptr"

	OS_ACQUIRE "dc_ascii"

	OS_FIND_EXPORT "DCUpdate_ascii", "DCUpdate_Ptr"

	lwz r0, 0x10 (r1)
	mtlr r0
	addi r1, r1, 0xC
	blr

/**========================================================================
 **                       OSFatal_ModuleLoadFailure
 *?  Displays an error message and halts the system.
 *========================================================================**/
OSFatal_ModuleLoadFailure:
	SET_SYMBOL_ADDR r3, "ModuleLoadFailure"
	b OSFatal

/**========================================================================
 **                        UpdateControllerBuffers
 *?  Updates VPad, WPad and KPad status and error buffers.
 *========================================================================**/
UpdateControllerBuffers:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0x10 (r1)
	stw r31, 0xC (r1)
	stw r30, 0x8 (r1)

	SET_ADDR r31, "CONTROLLER_STATUS_BUFFERS"

UpdateControllerBuffers_VPadUpdate:
	li r3, 0
	mr r4, r31
	li r5, 0x1
	addi r6, r4, 0xAC
	addi r30, r6, 0x4
	bl VPADRead
	lwz r5, 0 (r31)
	cmpwi r5, "VPAD_READ_UNINITIALIZED"
	beq UpdateControllerBuffers_InitVPAD
	mr r31, r30

UpdateControllerBuffers_KPADUpdate:
	li r3, 0
	mr r4, r31
	li r5, 0x1
	addi r6, r4, 0xF0
	addi r30, r6, 0x4
	bl KPADReadEx
	lwz r5, 0 (r31)
	cmpwi r5, "KPAD_ERROR_UNINITIALIZED"
	beq UpdateControllerBuffers_InitKPAD
	cmpwi r5, "KPAD_ERROR_WPAD_UNINIT"
	beq UpdateControllerBuffers_InitWPAD
	b UpdateControllerBuffers_OtherKPADUpdate

UpdateControllerBuffers_InitVPAD:
	bl VPADInit
	b UpdateControllerBuffers_VPadUpdate

UpdateControllerBuffers_InitKPAD:
	bl KPADInit
	b UpdateControllerBuffers_KPADUpdate

UpdateControllerBuffers_InitWPAD:
	bl WPADInit
	b UpdateControllerBuffers_KPADUpdate

UpdateControllerBuffers_OtherKPADUpdate:
	mr r31, r30

	li r3, 0x1
	mr r4, r31
	li r5, 0x1
	addi r6, r4, 0xF0
	addi r31, r6, 0x4
	bl KPADReadEx

	li r3, 0x2
	mr r4, r31
	li r5, 0x1
	addi r6, r4, 0xF0
	addi r31, r6, 0x4
	bl KPADReadEx

	li r3, 0x3
	mr r4, r31
	li r5, 0x1
	addi r6, r4, 0xF0
	addi r31, r6, 0x4
	bl KPADReadEx

UpdateControllerBuffers_exit:
	lwz r30, 0x8 (r1)
	lwz r31, 0xC (r1)
	lwz r0, 0x14 (r1)
	mtlr r0
	addi r1, r1, 0x10
	blr

/**========================================================================
 **                               DecodeList
 *?  Reads an array of bytes and performs various operations based on the
 *?  Cafe Code Type documentation.
 *?  Documentation: https://bullywiiplaza.website/wiiu/codetypes_EN.html
 *@param1 r3 "List Start" address
 *@param2 r4 "List End" address
 *========================================================================**/
DecodeList:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0xC (r1)
	stw r31, 0x8 (r1)

	mr r31, r4

DecodeNext:
	bl DecodeCodeType

	mr r4, r31
	cmplw r3, r31
	blt DecodeNext

	li r5, 0

	lis r12, "CODE_HANDLER_CONDITIONAL_FLAG"@ha
	stw r5, "CODE_HANDLER_CONDITIONAL_FLAG"@l (r12)

	lis r12, "CODE_HANDLER_COMPUTED_POINTER"@ha
	stw r5, "CODE_HANDLER_COMPUTED_POINTER"@l (r12)

	lis r12, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@ha
	stw r5, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@l (r12)

	lis r12, "CODE_HANDLER_0x80_CODETYPE_FLAG"@ha
	stw r5, "CODE_HANDLER_0x80_CODETYPE_FLAG"@l (r12)

	SET_ADDR r12, "CODE_HANDLER_PSEUDO_REGISTERS"

	li r0, 0x10
	mtctr r0

DecodeNext_ClearPseudoRegisters:
	stw r5, 0 (r12)
	addi r12, r12, 0x4
	bdnz DecodeNext_ClearPseudoRegisters

	lwz r31, 0x8 (r1)
	lwz r0, 0x10 (r1)
	mtlr r0
	addi r1, r1, 0xC
	blr

/**========================================================================
 **                             DecodeCodeType
 *?  Reads an array of bytes and performs various operations based on the
 *?  Cafe Code Type documentation.
 *?  Documentation: https://bullywiiplaza.website/wiiu/codetypes_EN.html
 *@param1 r3 "Code Type Start" address
 *@param2 r4 "List End" address
 *@return r3 "Code Type End" address
 *========================================================================**/
DecodeCodeType:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0x158 (r1)
	stmw r20, 0x128 (r1)

	mr r31, r3
	mr r30, r4

	SET_ADDR r29, "CODE_HANDLER_CONDITIONAL_FLAG"

	SET_ADDR r28, "CODE_HANDLER_COMPUTED_POINTER"

	SET_ADDR r5, "CODE_LIST_START_ADDRESS"

	SET_ADDR r6, "CODE_HANDLER_RESERVED_DATA"

	subf r5, r5, r31
	add r27, r5, r6

	SET_ADDR r26, "CODE_HANDLER_PSEUDO_REGISTERS"

	lbz r5, 0 (r31)
	slwi r0, r5, 2

	SET_SYMBOL_ADDR r12, "DecodeCodeType_switch_case"

	add r12, r12, r0
	mtctr r12
	bctr

DecodeCodeType_switch_case:
	b DecodeCodeType_RAMWrites # 0x00 | RAM Writes
	b DecodeCodeType_StringWrites # 0x01 | String Writes
	b DecodeCodeType_SkipWrites # 0x02 | Skip Writes
	b DecodeCodeType_CommonConditional # 0x03 | If Equal
	b DecodeCodeType_CommonConditional # 0x04 | Not Equal
	b DecodeCodeType_CommonConditional # 0x05 | Greater Than
	b DecodeCodeType_CommonConditional # 0x06 | Lower Than
	b DecodeCodeType_CommonConditional # 0x07 | Greater Or Equal
	b DecodeCodeType_CommonConditional # 0x08 | Lower Or Equal
	b DecodeCodeType_CommonConditional # 0x09 | Conditional AND
	b DecodeCodeType_CommonConditional # 0x0A | Conditional OR
	b DecodeCodeType_CommonConditional # 0x0B | If Value Between
	b DecodeCodeType_TimeDependence # 0x0C | Time Dependence
	b DecodeCodeType_ResetTimer # 0x0D | Reset Timer
	b DecodeCodeType_InputConditional # 0x0E | Input Conditional
	b DecodeCodeType_NegateConditional # 0x0F | Negate Conditional
	b DecodeCodeType_LoadInteger # 0x10 | Load Integer
	b DecodeCodeType_StoreInteger # 0x11 | Store Integer
	b DecodeCodeType_LoadFloat # 0x12 | Load Float
	b DecodeCodeType_StoreFloat # 0x13 | Store Float
	b DecodeCodeType_IntegerOperations # 0x14 | Integet Operation
	b DecodeCodeType_FloatOperations # 0x15 | Float Operation
	b DecodeCodeType_NoOperation # 0x16
	b DecodeCodeType_NoOperation # 0x17
	b DecodeCodeType_NoOperation # 0x18
	b DecodeCodeType_NoOperation # 0x19
	b DecodeCodeType_NoOperation # 0x1A
	b DecodeCodeType_NoOperation # 0x1B
	b DecodeCodeType_NoOperation # 0x1C
	b DecodeCodeType_NoOperation # 0x1D
	b DecodeCodeType_NoOperation # 0x1E
	b DecodeCodeType_NoOperation # 0x1F
	b DecodeCodeType_MemoryFill # 0x20 | Memory Fill
	b DecodeCodeType_MemoryCopy # 0x21 | Memory Copy
	b DecodeCodeType_NoOperation # 0x22
	b DecodeCodeType_NoOperation # 0x23
	b DecodeCodeType_NoOperation # 0x24
	b DecodeCodeType_NoOperation # 0x25
	b DecodeCodeType_NoOperation # 0x26
	b DecodeCodeType_NoOperation # 0x27
	b DecodeCodeType_NoOperation # 0x28
	b DecodeCodeType_NoOperation # 0x29
	b DecodeCodeType_NoOperation # 0x2A
	b DecodeCodeType_NoOperation # 0x2B
	b DecodeCodeType_NoOperation # 0x2C
	b DecodeCodeType_NoOperation # 0x2D
	b DecodeCodeType_NoOperation # 0x2E
	b DecodeCodeType_NoOperation # 0x2F
	b DecodeCodeType_DereferencePointer # 0x30 | Load Pointer
	b DecodeCodeType_PtrOffsetModfier # 0x31 | Add Offset To Pointer
	b DecodeCodeType_PtrOffsetModfier # 0x32 | Add Offset To Pointer Indexed
	b DecodeCodeType_PtrOffsetModfier # 0x33 | Subtract Offset From Pointer
	b DecodeCodeType_PtrOffsetModfier # 0x34 | Subtract Offset From Pointer Indexed
	b DecodeCodeType_NoOperation # 0x35
	b DecodeCodeType_NoOperation # 0x36
	b DecodeCodeType_NoOperation # 0x37
	b DecodeCodeType_NoOperation # 0x38
	b DecodeCodeType_NoOperation # 0x39
	b DecodeCodeType_NoOperation # 0x3A
	b DecodeCodeType_NoOperation # 0x3B
	b DecodeCodeType_NoOperation # 0x3C
	b DecodeCodeType_NoOperation # 0x3D
	b DecodeCodeType_NoOperation # 0x3E
	b DecodeCodeType_NoOperation # 0x3F
	b DecodeCodeType_NoOperation # 0x40
	b DecodeCodeType_NoOperation # 0x41
	b DecodeCodeType_NoOperation # 0x42
	b DecodeCodeType_NoOperation # 0x43
	b DecodeCodeType_NoOperation # 0x44
	b DecodeCodeType_NoOperation # 0x45
	b DecodeCodeType_NoOperation # 0x46
	b DecodeCodeType_NoOperation # 0x47
	b DecodeCodeType_NoOperation # 0x48
	b DecodeCodeType_NoOperation # 0x49
	b DecodeCodeType_NoOperation # 0x4A
	b DecodeCodeType_NoOperation # 0x4B
	b DecodeCodeType_NoOperation # 0x4C
	b DecodeCodeType_NoOperation # 0x4D
	b DecodeCodeType_NoOperation # 0x4E
	b DecodeCodeType_NoOperation # 0x4F
	b DecodeCodeType_NoOperation # 0x50
	b DecodeCodeType_NoOperation # 0x51
	b DecodeCodeType_NoOperation # 0x52
	b DecodeCodeType_NoOperation # 0x53
	b DecodeCodeType_NoOperation # 0x54
	b DecodeCodeType_NoOperation # 0x55
	b DecodeCodeType_NoOperation # 0x56
	b DecodeCodeType_NoOperation # 0x57
	b DecodeCodeType_NoOperation # 0x58
	b DecodeCodeType_NoOperation # 0x59
	b DecodeCodeType_NoOperation # 0x5A
	b DecodeCodeType_NoOperation # 0x5B
	b DecodeCodeType_NoOperation # 0x5C
	b DecodeCodeType_NoOperation # 0x5D
	b DecodeCodeType_NoOperation # 0x5E
	b DecodeCodeType_NoOperation # 0x5F
	b DecodeCodeType_NoOperation # 0x60
	b DecodeCodeType_NoOperation # 0x61
	b DecodeCodeType_NoOperation # 0x62
	b DecodeCodeType_NoOperation # 0x63
	b DecodeCodeType_NoOperation # 0x64
	b DecodeCodeType_NoOperation # 0x65
	b DecodeCodeType_NoOperation # 0x66
	b DecodeCodeType_NoOperation # 0x67
	b DecodeCodeType_NoOperation # 0x68
	b DecodeCodeType_NoOperation # 0x69
	b DecodeCodeType_NoOperation # 0x6A
	b DecodeCodeType_NoOperation # 0x6B
	b DecodeCodeType_NoOperation # 0x6C
	b DecodeCodeType_NoOperation # 0x6D
	b DecodeCodeType_NoOperation # 0x6E
	b DecodeCodeType_NoOperation # 0x6F
	b DecodeCodeType_NoOperation # 0x70
	b DecodeCodeType_NoOperation # 0x71
	b DecodeCodeType_NoOperation # 0x72
	b DecodeCodeType_NoOperation # 0x73
	b DecodeCodeType_NoOperation # 0x74
	b DecodeCodeType_NoOperation # 0x75
	b DecodeCodeType_NoOperation # 0x76
	b DecodeCodeType_NoOperation # 0x77
	b DecodeCodeType_NoOperation # 0x78
	b DecodeCodeType_NoOperation # 0x79
	b DecodeCodeType_NoOperation # 0x7A
	b DecodeCodeType_NoOperation # 0x7B
	b DecodeCodeType_NoOperation # 0x7C
	b DecodeCodeType_NoOperation # 0x7D
	b DecodeCodeType_NoOperation # 0x7E
	b DecodeCodeType_NoOperation # 0x7F
	b DecodeCodeType_Loop # 0x80 | Loop
	b DecodeCodeType_Loop # 0x81 | Loop Indexed
	b DecodeCodeType_BreakLoop # 0x82 | Break Loop
	b DecodeCodeType_NoOperation # 0x83
	b DecodeCodeType_NoOperation # 0x84
	b DecodeCodeType_NoOperation # 0x85
	b DecodeCodeType_NoOperation # 0x86
	b DecodeCodeType_NoOperation # 0x87
	b DecodeCodeType_NoOperation # 0x88
	b DecodeCodeType_NoOperation # 0x89
	b DecodeCodeType_NoOperation # 0x8A
	b DecodeCodeType_NoOperation # 0x8B
	b DecodeCodeType_NoOperation # 0x8C
	b DecodeCodeType_NoOperation # 0x8D
	b DecodeCodeType_NoOperation # 0x8E
	b DecodeCodeType_NoOperation # 0x8F
	b DecodeCodeType_NoOperation # 0x90
	b DecodeCodeType_NoOperation # 0x91
	b DecodeCodeType_NoOperation # 0x92
	b DecodeCodeType_NoOperation # 0x93
	b DecodeCodeType_NoOperation # 0x94
	b DecodeCodeType_NoOperation # 0x95
	b DecodeCodeType_NoOperation # 0x96
	b DecodeCodeType_NoOperation # 0x97
	b DecodeCodeType_NoOperation # 0x98
	b DecodeCodeType_NoOperation # 0x99
	b DecodeCodeType_NoOperation # 0x9A
	b DecodeCodeType_NoOperation # 0x9B
	b DecodeCodeType_NoOperation # 0x9C
	b DecodeCodeType_NoOperation # 0x9D
	b DecodeCodeType_NoOperation # 0x9E
	b DecodeCodeType_NoOperation # 0x9F
	b DecodeCodeType_NoOperation # 0xA0
	b DecodeCodeType_NoOperation # 0xA1
	b DecodeCodeType_NoOperation # 0xA2
	b DecodeCodeType_NoOperation # 0xA3
	b DecodeCodeType_NoOperation # 0xA4
	b DecodeCodeType_NoOperation # 0xA5
	b DecodeCodeType_NoOperation # 0xA6
	b DecodeCodeType_NoOperation # 0xA7
	b DecodeCodeType_NoOperation # 0xA8
	b DecodeCodeType_NoOperation # 0xA9
	b DecodeCodeType_NoOperation # 0xAA
	b DecodeCodeType_NoOperation # 0xAB
	b DecodeCodeType_NoOperation # 0xAC
	b DecodeCodeType_NoOperation # 0xAD
	b DecodeCodeType_NoOperation # 0xAE
	b DecodeCodeType_NoOperation # 0xAF
	b DecodeCodeType_NoOperation # 0xB0
	b DecodeCodeType_NoOperation # 0xB1
	b DecodeCodeType_NoOperation # 0xB2
	b DecodeCodeType_NoOperation # 0xB3
	b DecodeCodeType_NoOperation # 0xB4
	b DecodeCodeType_NoOperation # 0xB5
	b DecodeCodeType_NoOperation # 0xB6
	b DecodeCodeType_NoOperation # 0xB7
	b DecodeCodeType_NoOperation # 0xB8
	b DecodeCodeType_NoOperation # 0xB9
	b DecodeCodeType_NoOperation # 0xBA
	b DecodeCodeType_NoOperation # 0xBB
	b DecodeCodeType_NoOperation # 0xBC
	b DecodeCodeType_NoOperation # 0xBD
	b DecodeCodeType_NoOperation # 0xBE
	b DecodeCodeType_NoOperation # 0xBF
	b DecodeCodeType_ExecuteASM # 0xC0 | Execute ASM
	b DecodeCodeType_ProcedureAndSyscalls # 0xC1 | System- And Procedure Calls
	b DecodeCodeType_InsertASM # 0xC2 | Insert ASM Via LR
	b DecodeCodeType_InsertASM # 0xC3 | Insert ASM Via CTR
	b DecodeCodeType_ASMStringWrites # 0xC4 | ASM String Writes
	b DecodeCodeType_NoOperation # 0xC5
	b DecodeCodeType_NoOperation # 0xC6
	b DecodeCodeType_NoOperation # 0xC7
	b DecodeCodeType_NoOperation # 0xC8
	b DecodeCodeType_NoOperation # 0xC9
	b DecodeCodeType_NoOperation # 0xCA
	b DecodeCodeType_NoOperation # 0xCB
	b DecodeCodeType_NoOperation # 0xCC
	b DecodeCodeType_NoOperation # 0xCD
	b DecodeCodeType_NoOperation # 0xCE
	b DecodeCodeType_NoOperation # 0xCF
	b DecodeCodeType_Terminator # 0xD0 | Terminator
	b DecodeCodeType_LoopTerminator # 0xD1 | Loop Terminator
	b DecodeCodeType_ConditionalTerminator # 0xD2 | Conditional Terminator
	b DecodeCodeType_NoOperation # 0xD3
	b DecodeCodeType_NoOperation # 0xD4
	b DecodeCodeType_NoOperation # 0xD5
	b DecodeCodeType_NoOperation # 0xD6
	b DecodeCodeType_NoOperation # 0xD7
	b DecodeCodeType_NoOperation # 0xD8
	b DecodeCodeType_NoOperation # 0xD9
	b DecodeCodeType_NoOperation # 0xDA
	b DecodeCodeType_NoOperation # 0xDB
	b DecodeCodeType_NoOperation # 0xDC
	b DecodeCodeType_NoOperation # 0xDD
	b DecodeCodeType_NoOperation # 0xDE
	b DecodeCodeType_NoOperation # 0xDF
	b DecodeCodeType_DisplayMessageAndPause # 0xE0 | Display Message And Pause
	b DecodeCodeType_DisplayPointerMessageAndPause # 0xE1 | Display Pointer Message And Pause
	b DecodeCodeType_ClearMessageAndResume # 0xE2 | Clear Message And Resume
	b DecodeCodeType_NoOperation # 0xE3
	b DecodeCodeType_NoOperation # 0xE4
	b DecodeCodeType_NoOperation # 0xE5
	b DecodeCodeType_NoOperation # 0xE6
	b DecodeCodeType_NoOperation # 0xE7
	b DecodeCodeType_NoOperation # 0xE8
	b DecodeCodeType_NoOperation # 0xE9
	b DecodeCodeType_NoOperation # 0xEA
	b DecodeCodeType_NoOperation # 0xEB
	b DecodeCodeType_NoOperation # 0xEC
	b DecodeCodeType_NoOperation # 0xED
	b DecodeCodeType_NoOperation # 0xEE
	b DecodeCodeType_NoOperation # 0xEF
	b DecodeCodeType_Corruptor # 0xF0 | Corruptor
	b DecodeCodeType_NoOperation # 0xF1
	b DecodeCodeType_NoOperation # 0xF2
	b DecodeCodeType_NoOperation # 0xF3
	b DecodeCodeType_NoOperation # 0xF4
	b DecodeCodeType_NoOperation # 0xF5
	b DecodeCodeType_NoOperation # 0xF6
	b DecodeCodeType_NoOperation # 0xF7
	b DecodeCodeType_NoOperation # 0xF8
	b DecodeCodeType_NoOperation # 0xF9
	b DecodeCodeType_NoOperation # 0xFA
	b DecodeCodeType_NoOperation # 0xFB
	b DecodeCodeType_NoOperation # 0xFC
	b DecodeCodeType_NoOperation # 0xFD
	b DecodeCodeType_NoOperation # 0xFE
	b DecodeCodeType_NoOperation # 0xFF

#! ------------------------------------------------------------------------
#!                             RAM Writes [00]
#! ------------------------------------------------------------------------
DecodeCodeType_RAMWrites:
	lbz r6, 0x1 (r31)
	rlwinm. r0, r6, 28, 28, 31 # Extract "isPointer" bits.
	clrlwi r26, r6, 28 # Extract "dataSize" bits.
	beq DecodeCodeType_RAMWrites_NoPtr

	lwz r12, 0 (r28) # Computed pointer.
	lhz r0, 0x2 (r31) # Unsigned volatile offset "KKKK".
	add r25, r12, r0
	lwz r24, 0x4 (r31) # Value VVVVVVVV.
	addi r31, r31, 0x8 # Code type length.
	b DecodeCodeType_RAMWrites_General

DecodeCodeType_RAMWrites_NoPtr:
	lwz r25, 0x4 (r31) # Address LLLLLLLL.
	lwz r24, 0x8 (r31) # Value VVVVVVVV.
	addi r31, r31, 0x10 # Code type length.

DecodeCodeType_RAMWrites_General:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	cmpw r25, r5
	bne DecodeCodeType_RAMWrites_CheckAddr
	
	mr r31, r30
	b DecodeCodeType_Exit

DecodeCodeType_RAMWrites_CheckAddr:
	mr r3, r25
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r25, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit
	cmplwi r0, 0x1000
	bge DecodeCodeType_RAMWrites_DataWrites_8bit

	lwz r5, 0 (r27) # Get write flag.
	cmpw r5, r25
	beq+ DecodeCodeType_Exit
	stw r25, 0 (r27) # Set write flag.

#* Run code below if the code memory region is detected.
	addi r12, r1, 0x8

DecodeCodeType_RAMWrites_CodeWrites_8bit:
	cmpwi r26, 0
	bne DecodeCodeType_RAMWrites_CodeWrites_16bit
	stb r24, 0 (r12)
	b DecodeCodeType_RAMWrites_CodeWrites_Generic

DecodeCodeType_RAMWrites_CodeWrites_16bit:
	cmpwi r26, 0x1
	bne DecodeCodeType_RAMWrites_CodeWrites_32bit
	sth r24, 0 (r12)
	b DecodeCodeType_RAMWrites_CodeWrites_Generic

DecodeCodeType_RAMWrites_CodeWrites_32bit:
	li r26, 0x3
	stw r24, 0 (r12)

DecodeCodeType_RAMWrites_CodeWrites_Generic:
	mr r3, r25
	mr r4, r12
	addi r5, r26, 0x1

	FLUSH_DATA_BLOCK r12

	bl KernelCopyData

	b DecodeCodeType_Exit

#* Run code below if the data memory region is detected.
DecodeCodeType_RAMWrites_DataWrites_8bit:
	cmpwi r26, 0
	bne DecodeCodeType_RAMWrites_DataWrites_16bit
	stb r24, 0 (r25)
	b DecodeCodeType_Exit

DecodeCodeType_RAMWrites_DataWrites_16bit:
	cmpwi r26, 0x1
	bne DecodeCodeType_RAMWrites_DataWrites_32bit
	sth r24, 0 (r25)
	b DecodeCodeType_Exit

DecodeCodeType_RAMWrites_DataWrites_32bit:
	stw r24, 0 (r25)
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                            String Writes [01]
#! ------------------------------------------------------------------------
DecodeCodeType_StringWrites:
	lbz r5, 0x1 (r31)
	lwz r26, 0x4 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.
	addi r25, r31, 0x8 # Value/String VV...
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	beq DecodeCodeType_StringWrites_NoPtr
	lwz r12, 0 (r28)
	add r26, r26, r12

DecodeCodeType_StringWrites_NoPtr:
	lhz r24, 0x2 (r31) # String length NNNN.
	li r6, 0x8
	divw r6, r24, r6 # Get number of whole codelines.
	andi. r0, r24, 0x7 # Modulo.
	beq DecodeCodeType_StringWrites_CalcLength
	addi r6, r6, 0x1 # Round up towards next 0x8.

DecodeCodeType_StringWrites_CalcLength:
	mulli r6, r6, 0x8
	addi r6, r6, 0x8 # Include the initial codeline.
	add r31, r31, r6
	cmpw r31, r30 # Check available space.
	blt+ DecodeCodeType_StringWrites_General
	mr r31, r30
	b DecodeCodeType_Exit

DecodeCodeType_StringWrites_General:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	mr r3, r26 # Check if target address is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	add r3, r26, r24 # Check if end address is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	mr r3, r26
	mr r4, r25
	mr r5, r24

	srwi r0, r26, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit
	cmplwi r0, 0x1000
	bge DecodeCodeType_StringWrites_DataWrites

	lwz r5, 0 (r27) # Get write flag.
	cmpw r5, r26
	beq+ DecodeCodeType_Exit
	stw r26, 0 (r27) # Set write flag.

	bl KernelCopyData

	b DecodeCodeType_Exit

DecodeCodeType_StringWrites_DataWrites:
	bl memcpy

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                             Skip Writes [02]
#! ------------------------------------------------------------------------
DecodeCodeType_SkipWrites:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	clrlwi r26, r5, 28 # Extract "dataSize" bits.
	lwz r25, 0x4 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.
	beq DecodeCodeType_SkipWrites_General
	lwz r12, 0 (r28) # Computed pointer.
	add r25, r25, r12

DecodeCodeType_SkipWrites_General:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_SkipWrites_ResetWriteFlagAndExit

	lhz r24, 0x2 (r31) # Amount of writes (NNNN).
	cmpwi r24, 0
	beq DecodeCodeType_SkipWrites_Exit

	mr r3, r25 # Check if start address is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_SkipWrites_Exit

	lwz r23, 0xC (r31) # Address space YYYYYYYY.

	mullw r5, r23, r24 # LLLLLLLL + NNNN.
	add r3, r25, r5 # Check if end address is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_SkipWrites_Exit

	lwz r22, 0x10 (r31) # Value IIIIIIII.
	lwz r21, 0x8 (r31) # Value VVVVVVVV.
	lis r20, 0x1000 # Data memory section start.

	srwi r0, r25, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_SkipWrites_Exit
	cmplw r25, r20
	bge DecodeCodeType_SkipWrites_8bit_DataWrites

#* Run code below if the code memory region is detected.
	lwz r5, 0 (r27) # Get write flag.
	cmpw r5, r25
	beq+ DecodeCodeType_SkipWrites_Exit
	stw r25, 0 (r27) # Set write flag.

	cmpwi r26, 0
	bne DecodeCodeType_SkipWrites_16bit_CodeWrites

DecodeCodeType_SkipWrites_8bit_CodeWrites_Next:
	cmplw r25, r20
	bge DecodeCodeType_SkipWrites_Exit

	addi r12, r1, 0x8

	stb r21, 0 (r12)

	FLUSH_DATA_BLOCK r12

	mr r3, r25
	mr r4, r12
	li r5, 0x1
	bl KernelCopyData

	add r21, r21, r22
	add r25, r25, r23

	subic. r24, r24, 0x1
	bne DecodeCodeType_SkipWrites_8bit_CodeWrites_Next
	b DecodeCodeType_SkipWrites_Exit

DecodeCodeType_SkipWrites_16bit_CodeWrites:
	cmpwi r26, 0x1
	bne DecodeCodeType_SkipWrites_32bit_CodeWrites_Next

DecodeCodeType_SkipWrites_16bit_CodeWrites_Next:
	cmplw r25, r20
	bge DecodeCodeType_SkipWrites_Exit

	addi r12, r1, 0x8

	sth r21, 0 (r12)

	FLUSH_DATA_BLOCK r12

	mr r3, r25
	mr r4, r12
	li r5, 0x2
	bl KernelCopyData

	add r21, r21, r22
	add r25, r25, r23

	subic. r24, r24, 0x1
	bne DecodeCodeType_SkipWrites_16bit_CodeWrites_Next
	b DecodeCodeType_SkipWrites_Exit

DecodeCodeType_SkipWrites_32bit_CodeWrites_Next:
	cmplw r25, r20
	bge DecodeCodeType_SkipWrites_Exit

	mr r3, r25
	mr r4, r21
	bl InstructionPatcher

	add r21, r21, r22
	add r25, r25, r23

	subic. r24, r24, 0x1
	bne DecodeCodeType_SkipWrites_32bit_CodeWrites_Next
	b DecodeCodeType_SkipWrites_Exit

#* Run code below if the data memory region is detected.
DecodeCodeType_SkipWrites_8bit_DataWrites:
	cmpwi r26, 0
	bne DecodeCodeType_SkipWrites_16bit_DataWrites

DecodeCodeType_SkipWrites_8bit_DataWrites_Next:
	stb r21, 0 (r25)
	add r21, r21, r22
	add r25, r25, r23

	subic. r24, r24, 0x1
	bne DecodeCodeType_SkipWrites_8bit_DataWrites_Next
	b DecodeCodeType_SkipWrites_Exit

DecodeCodeType_SkipWrites_16bit_DataWrites:
	cmpwi r26, 0x1
	bne DecodeCodeType_SkipWrites_32bit_DataWrites

DecodeCodeType_SkipWrites_16bit_DataWrites_Next:
	sth r21, 0 (r25)
	add r21, r21, r22
	add r25, r25, r23

	subic. r24, r24, 0x1
	bne DecodeCodeType_SkipWrites_16bit_DataWrites_Next
	b DecodeCodeType_SkipWrites_Exit

DecodeCodeType_SkipWrites_32bit_DataWrites:
	stw r21, 0 (r25)

	add r21, r21, r22
	add r25, r25, r23

	subic. r24, r24, 0x1
	bne DecodeCodeType_SkipWrites_32bit_DataWrites
	b DecodeCodeType_SkipWrites_Exit

DecodeCodeType_SkipWrites_ResetWriteFlagAndExit:
	li r0, 0
	stb r0, 0 (r27) # Set write flag.

DecodeCodeType_SkipWrites_Exit:
	addi r31, r31, 0x18
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                           Common Conditionals
#! ------------------------------------------------------------------------
DecodeCodeType_CommonConditional:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	clrlwi r26, r5, 28 # Extract "dataSize" bits.
	lwz r25, 0x4 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.
	beq DecodeCodeType_CommonConditional_General
	lwz r12, 0 (r28) # Computed pointer.
	add r25, r25, r12

DecodeCodeType_CommonConditional_General:
	lhz r24, 0 (r29) # Conditional counter.
	addi r24, r24, 0x1
	sth r24, 0 (r29)

	lhz r0, 0x2 (r29) # Conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_CommonConditional_Exit

	mr r3, r25 # Check if address is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_CommonConditional_SetFlag

	srwi r0, r25, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_CommonConditional_SetFlag

DecodeCodeType_CommonConditional_8bit:
	cmpwi r26, 0
	bne DecodeCodeType_CommonConditional_16bit
	lbz r5, 0xB (r31)
	lbz r6, 0xF (r31)
	lbz r7, 0 (r25)
	b DecodeCodeType_CommonConditional_GotoSpecific

DecodeCodeType_CommonConditional_16bit:
	cmpwi r26, 0x1
	bne DecodeCodeType_CommonConditional_32bit
	lhz r5, 0xA (r31)
	lhz r6, 0xE (r31)
	lhz r7, 0 (r25)
	b DecodeCodeType_CommonConditional_GotoSpecific

DecodeCodeType_CommonConditional_32bit:
	lwz r5, 0x8 (r31)
	lwz r6, 0xC (r31)
	lwz r7, 0 (r25)

DecodeCodeType_CommonConditional_GotoSpecific:
	lbz r8, 0 (r31)
	subi r8, r8, 0x3
	cmplwi r8, 0x8
	bgt DecodeCodeType_CommonConditional_Exit
	mulli r8, r8, 0x10

	SET_SYMBOL_ADDR r12, "DecodeCodeType_CommonConditional_switch_case"

	add r12, r12, r8
	mtctr r12
	bctr

DecodeCodeType_CommonConditional_switch_case:
#! ------------------------------------------------------------------------
#!                              If Equal [03]
#! ------------------------------------------------------------------------
	nop
	cmpw r7, r5
	bne DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                            If Not Equal [04]
#! ------------------------------------------------------------------------
	nop
	cmpw r7, r5
	beq DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                             If Greater [05]
#! ------------------------------------------------------------------------
	nop
	cmpw r7, r5
	ble DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                              If Lower [06]
#! ------------------------------------------------------------------------
	nop
	cmpw r7, r5
	bge DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                         If Greater Or Equal [07]
#! ------------------------------------------------------------------------
	nop
	cmpw r7, r5
	blt DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                          If Lower Or Equal [08]
#! ------------------------------------------------------------------------
	nop
	cmpw r7, r5
	bgt DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                           Conditional AND [09]
#! ------------------------------------------------------------------------
	and r7, r7, r5
	cmpw r7, r5
	bne DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                           Conditional OR [0A]
#! ------------------------------------------------------------------------
	nop
	and. r7, r7, r5
	beq DecodeCodeType_CommonConditional_SetFlag
	b DecodeCodeType_CommonConditional_Exit

#! ------------------------------------------------------------------------
#!                               Between [0B]
#! ------------------------------------------------------------------------
	cmpw r7, r5
	ble DecodeCodeType_CommonConditional_SetFlag
	cmpw r7, r6
	blt DecodeCodeType_CommonConditional_Exit

DecodeCodeType_CommonConditional_SetFlag:
	sth r24, 0x2 (r29) # Set conditional flag.

DecodeCodeType_CommonConditional_Exit:
	addi r31, r31, 0x10
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                           Time Dependence [0C]
#! ------------------------------------------------------------------------
DecodeCodeType_TimeDependence:
	lwz r5, 0 (r27) # Get passed frames.
	lwz r6, 0x4 (r31) # Get TTTTTTTT frames.

	addi r31, r31, 0x8

	lis r12, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@ha
	stw r27, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@l (r12) # Used by "Reset Timer" 0x0D code type.

	lhz r7, 0 (r29) # Conditional counter.
	addi r7, r7, 0x1
	sth r7, 0 (r29)

	lis r12, "CODE_HANDLER_0x80_CODETYPE_FLAG"@ha
	lwz r0, "CODE_HANDLER_0x80_CODETYPE_FLAG"@l (r12) # Used by "Loop" code types.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	lhz r0, 0x2 (r29) # Conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	cmplw r5, r6
	addi r5, r5, 0x1
	stw r5, 0 (r27)
	blt DecodeCodeType_Exit
	sth r7, 0x2 (r29) # Set conditional flag.
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                             Reset Timer [0D]
#! ------------------------------------------------------------------------
DecodeCodeType_ResetTimer:
	lwz r26, 0x4 (r31) # Address LLLLLLLL.
	lhz r25, 0x2 (r31) # Value VVVV.

	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	lis r12, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@ha
	lwz r24, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@l (r12) # Previous time dependent codetype timer.
	cmpwi r24, 0
	beq DecodeCodeType_Exit

	mr r3, r26
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	lhz r5, 0 (r26)
	cmpw r5, r25
	bne DecodeCodeType_Exit
	li r0, 0
	stw r0, 0 (r24)
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                          Input Conditional [0E]
#! ------------------------------------------------------------------------
DecodeCodeType_InputConditional:
	lbz r5, 0x2 (r31) # Get "X" controller type.
	lbz r6, 0x3 (r31) # Get "Y" controller port.
	lwz r7, 0x4 (r31) # Value VVVVVVVV.

	addi r31, r31, 0x8

	lhz r8, 0 (r29) # Conditional counter.
	addi r8, r8, 0x1
	sth r8, 0 (r29)

	lhz r0, 0x2 (r29) # Conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	cmplwi r5, 0x3
	bgt DecodeCodeType_Exit
	cmplwi r6, 0x3
	bgt DecodeCodeType_Exit

	SET_ADDR r11, "CONTROLLER_STATUS_BUFFERS"

	mulli r5, r5, 0xC
	mulli r6, r6, 0xF4

	SET_SYMBOL_ADDR r12, "DecodeCodeType_InputConditional_switch_case"

	add r12, r12, r5
	mtctr r12
	bctr

DecodeCodeType_InputConditional_switch_case:
	li r9, 0xAC # Wii U GamePad Error.
	li r6, 0 # Wii U GamePad Hold Buttons.
	b DecodeCodeType_InputConditional_DecideFlag

	addi r9, r6, 0x1A0 # WiiMote Error.
	addi r6, r6, 0xB0 # WiiMote Hold Buttons.
	b DecodeCodeType_InputConditional_DecideFlag

	addi r9, r6, 0x1A0 # WiiMote Error.
	addi r6, r6, 0x12C # WiiMote + Nunchuck.
	b DecodeCodeType_InputConditional_DecideFlag

	addi r9, r6, 0x1A0 # WiiMote Error.
	addi r6, r6, 0x110 # Classic/Pro Controller.

DecodeCodeType_InputConditional_DecideFlag:
	lwzx r9, r11, r9
	cmpwi r9, 0
	bne DecodeCodeType_InputConditional_SetFlag

	lwzx r10, r11, r6
	and r10, r10, r7
	cmpw r10, r7
	beq DecodeCodeType_Exit

DecodeCodeType_InputConditional_SetFlag:
	sth r8, 0x2 (r29)
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                         Negate Conditional [0F]
#! ------------------------------------------------------------------------
DecodeCodeType_NegateConditional:
	lhz r5, 0 (r29) # Conditional counter.
	lhz r6, 0x2 (r29) # Conditional flag.
	cmpwi r6, 0
	beq DecodeCodeType_NegateConditional_SetFlag
	cmpw r5, r6
	bne DecodeCodeType_NoOperation

DecodeCodeType_NegateConditional_SetFlag:
	xor r6, r6, r5
	sth r6, 0x2 (r29)
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                            Load Integer [10]
#! ------------------------------------------------------------------------
DecodeCodeType_LoadInteger:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	clrlwi r25, r5, 28 # Extract "dataSize" bits.
	lwz r24, 0x4 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.
	lbz r23, 0x3 (r31) # Integer register "R".
	beq DecodeCodeType_LoadInteger_General
	lwz r12, 0 (r28) # Computed pointer.
	add r24, r24, r12

DecodeCodeType_LoadInteger_General:
	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	mr r3, r24
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r24, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit

	clrlwi r23, r23, 29
	slwi r12, r23, 2

	lwz r5, 0 (r24)

	cmpwi r25, 0
	bne DecodeCodeType_LoadInteger_16bit
	clrlwi r5, r5, 24 # Reduce value to 8-bit.
	b DecodeCodeType_LoadInteger_UpdateIntRegister

DecodeCodeType_LoadInteger_16bit:
	cmpwi r25, 0x1
	bne DecodeCodeType_LoadInteger_UpdateIntRegister
	clrlwi r5, r5, 16 # Reduce value to 16-bit.

DecodeCodeType_LoadInteger_UpdateIntRegister:
	stwx r5, r26, r12
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                            Store Integer [11]
#! ------------------------------------------------------------------------
DecodeCodeType_StoreInteger:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	clrlwi r25, r5, 28 # Extract "dataSize" bits.
	lwz r24, 0x4 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.
	lbz r23, 0x3 (r31) # Integer register "R".
	beq DecodeCodeType_StoreInteger_General
	lwz r12, 0 (r28) # Computed pointer.
	add r24, r24, r12

DecodeCodeType_StoreInteger_General:
	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	mr r3, r24
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	clrlwi r23, r23, 29
	slwi r12, r23, 2

	lwzx r5, r26, r12

	srwi r0, r24, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit
	cmplwi r0, 0x1000
	bge DecodeCodeType_StoreInteger_Data_8bit

	addi r12, r1, 0x8

#* Run code below if the code memory region is detected.
	cmpwi r25, 0
	bne DecodeCodeType_StoreInteger_Code_16bit
	clrlwi r5, r5, 24 # Reduce value to 8-bit.
	lbz r6, 0 (r24)
	cmpw r5, r6
	beq DecodeCodeType_Exit
	stb r5, 0 (r12)
	b DecodeCodeType_StoreInteger_Code_Generic

DecodeCodeType_StoreInteger_Code_16bit:
	cmpwi r25, 0x1
	bne DecodeCodeType_StoreInteger_Code_32bit
	clrlwi r5, r5, 16 # Reduce value to 16-bit.
	lhz r6, 0 (r24)
	cmpw r5, r6
	beq DecodeCodeType_Exit
	sth r5, 0 (r12)
	b DecodeCodeType_StoreInteger_Code_Generic

DecodeCodeType_StoreInteger_Code_32bit:
	li r25, 0x3
	lwz r6, 0 (r24)
	cmpw r5, r6
	beq DecodeCodeType_Exit
	stw r5, 0 (r12)

DecodeCodeType_StoreInteger_Code_Generic:
	mr r3, r24
	mr r4, r12
	addi r5, r25, 0x1

	FLUSH_DATA_BLOCK r12

	bl KernelCopyData

	b DecodeCodeType_Exit

#* Run code below if the data memory region is detected.
DecodeCodeType_StoreInteger_Data_8bit:
	cmpwi r25, 0
	bne DecodeCodeType_StoreInteger_Data_16bit
	stb r5, 0 (r24)
	b DecodeCodeType_Exit

DecodeCodeType_StoreInteger_Data_16bit:
	cmpwi r25, 0x1
	bne DecodeCodeType_StoreInteger_Data_Generic
	sth r5, 0 (r24)
	b DecodeCodeType_Exit

DecodeCodeType_StoreInteger_Data_Generic:
	stw r5, 0 (r24)
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                             Load Float [12]
#! ------------------------------------------------------------------------
DecodeCodeType_LoadFloat:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	lwz r25, 0x4 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.
	lbz r24, 0x3 (r31) # Integer register "R".
	beq DecodeCodeType_LoadFloat_General
	lwz r12, 0 (r28) # Computed pointer.
	add r25, r25, r12

DecodeCodeType_LoadFloat_General:
	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	mr r3, r25
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r25, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit

	clrlwi r24, r24, 29
	slwi r12, r24, 2
	addi r12, r12, 0x20

	lfs f5, 0 (r25)
	stfsx f5, r26, r12
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                             Store Float [13]
#! ------------------------------------------------------------------------
DecodeCodeType_StoreFloat:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	lwz r25, 0x4 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.
	lbz r24, 0x3 (r31) # Integer register "R".
	beq DecodeCodeType_StoreFloat_General
	lwz r12, 0 (r28) # Computed pointer.
	add r25, r25, r12

DecodeCodeType_StoreFloat_General:
	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	mr r3, r25
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	clrlwi r24, r24, 29
	slwi r12, r24, 2
	addi r12, r12, 0x20

	lfsx f5, r26, r12

	srwi r0, r25, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit
	cmplwi r0, 0x1000
	bge DecodeCodeType_StoreFloat_Data

	addi r12, r1, 0x8

#* Run code below if the code memory region is detected.
	lfs f6, 0 (r25)
	fcmpu cr0, f5, f6
	beq DecodeCodeType_Exit

	stfs f5, 0 (r12)

	FLUSH_DATA_BLOCK r12
	
	mr r3, r25
	mr r4, r12
	li r5, 0x4
	bl KernelCopyData

	b DecodeCodeType_Exit

#* Run code below if the data memory region is detected.
DecodeCodeType_StoreFloat_Data:
	stfs f5, 0 (r25)
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                         Integer Operations [14]
#! ------------------------------------------------------------------------
DecodeCodeType_IntegerOperations:
	lbz r5, 0x1 (r31) # Operation type "O".
	lbz r6, 0x2 (r31) # Integer register "R".
	lbz r7, 0x3 (r31) # Integer register "S".
	lwz r8, 0x4 (r31) # Value VVVVVVVV.

	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	clrlwi r5, r5, 28
	slwi r5, r5, 2

	clrlwi r6, r6, 29
	slwi r6, r6, 2

	clrlwi r7, r7, 29
	slwi r7, r7, 2

	lwzx r9, r26, r6 # Integer register "R" value.
	lwzx r10, r26, r7 # Integer register "S" value.
	addi r12, r7, 0x20 # Float register pointer.

	SET_SYMBOL_ADDR r11, "DecodeCodeType_IntegerOperations_switch_case"

	add r11, r11, r5
	mtctr r11
	bctr

DecodeCodeType_IntegerOperations_switch_case:
	b DecodeCodeType_IntegerOperations_AddReg # 0x0 (R + S)
	b DecodeCodeType_IntegerOperations_SubReg # 0x1 (R - S)
	b DecodeCodeType_IntegerOperations_MullReg # 0x2 (R * S)
	b DecodeCodeType_IntegerOperations_DivReg # 0x3 (R / S)
	b DecodeCodeType_IntegerOperations_AddVal # 0x4 (R + VVVVVVVV)
	b DecodeCodeType_IntegerOperations_SubVal # 0x5 (R - VVVVVVVV)
	b DecodeCodeType_IntegerOperations_MullVal # 0x6 (R * VVVVVVVV)
	b DecodeCodeType_IntegerOperations_DivVal # 0x7 (R / VVVVVVVV)
	b DecodeCodeType_IntegerOperations_ConvertToFloat # 0x8 (R to S float)
	b DecodeCodeType_IntegerOperations_AndReg # 0x9 (R & S)
	b DecodeCodeType_IntegerOperations_OrReg # 0xA (R | S)
	b DecodeCodeType_IntegerOperations_XorReg # 0xB (R ^ S)
	b DecodeCodeType_IntegerOperations_AndVal # 0xC (R & VVVVVVVV)
	b DecodeCodeType_IntegerOperations_OrVal # 0xD (R | VVVVVVVV)
	b DecodeCodeType_IntegerOperations_XorVal # 0xE (R ^ VVVVVVVV)
	b DecodeCodeType_IntegerOperations_AssignVal # 0xF (R = VVVVVVVV)

DecodeCodeType_IntegerOperations_AddReg:
	add r9, r9, r10
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_SubReg:
	sub r9, r9, r10
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_MullReg:
	mullw r9, r9, r10
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_DivReg:
	divw r9, r9, r10
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_AddVal:
	add r9, r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_SubVal:
	sub r9, r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_MullVal:
	mullw r9, r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_DivVal:
	divw r9, r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_ConvertToFloat:
	SET_SYMBOL_ADDR r11, "IntToFloat_magic"

	lwz r5, 0 (r11)
	stw r5, 0x8 (r1)
	xoris r9, r9, 0x8000
	stw r9, 0xC (r1)
	lfd f5, 0x8 (r1)
	lfd f6, 0 (r11)
	fsub f5, f5, f6
	stfsx f5, r26, r12
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_AndReg:
	and r9, r9, r10
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_OrReg:
	or r9, r9, r10
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_XorReg:
	xor r9, r9, r10
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_AndVal:
	and r9, r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_OrVal:
	or r9, r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_XorVal:
	xor r9, r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

DecodeCodeType_IntegerOperations_AssignVal:
	mr r9, r8
	stwx r9, r26, r6
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                          Float Operations [15]
#! ------------------------------------------------------------------------
DecodeCodeType_FloatOperations:
	lbz r5, 0x1 (r31) # Operation type "O".
	lbz r6, 0x2 (r31) # Integer register "R".
	lbz r7, 0x3 (r31) # Integer register "S".
	lfs f5, 0x4 (r31) # Value VVVVVVVV.

	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	clrlwi r5, r5, 28

	mulli r5, r5, 0xC

	clrlwi r6, r6, 29
	slwi r6, r6, 2
	addi r6, r6, 0x20

	clrlwi r7, r7, 29
	slwi r7, r7, 2
	mr r12, r7 # Integer register pointer.
	addi r7, r7, 0x20

	lfsx f6, r26, r6 # Float register "R" value.
	lfsx f7, r26, r7 # Float register "S" value.

	SET_SYMBOL_ADDR r11, "DecodeCodeType_FloatOperations_switch_case"

	add r11, r11, r5
	mtctr r11
	bctr

DecodeCodeType_FloatOperations_switch_case:
	fadds f6, f6, f7
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fsubs f6, f6, f7
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fmuls f6, f6, f7
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fdivs f6, f6, f7
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fadds f6, f6, f5
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fsubs f6, f6, f5
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fmuls f6, f6, f5
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fdivs f6, f6, f5
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

	fctiwz f6, f6
	stfiwx f6, r26, r12
	b DecodeCodeType_Exit

	nop
	nop
	b DecodeCodeType_Exit

	nop
	nop
	b DecodeCodeType_Exit

	nop
	nop
	b DecodeCodeType_Exit

	nop
	nop
	b DecodeCodeType_Exit

	nop
	nop
	b DecodeCodeType_Exit

	nop
	nop
	b DecodeCodeType_Exit

	fmr f6, f5
	stfsx f6, r26, r6
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                             Memory Fill [20]
#! ------------------------------------------------------------------------
DecodeCodeType_MemoryFill:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	lwz r26, 0x8 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.

	ROUND_UP_TO_ALIGNED r26

	lwz r25, 0x4 (r31) # Value VVVVVVVV.
	lwz r24, 0xC (r31) # Range MMMMMMMM.

	ROUND_UP_TO_ALIGNED r24

	beq DecodeCodeType_MemoryFill_General
	lwz r12, 0 (r28) # Computed pointer.
	add r26, r26, r12

DecodeCodeType_MemoryFill_General:
	addi r31, r31, 0x10

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	mr r3, r26 # Check start address.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	add r3, r26, r24
	subi r3, r3, 0x4 # Check end address.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r26, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit

	lwz r5, 0 (r27) # Get write flag.
	cmpw r5, r26
	beq+ DecodeCodeType_Exit
	stw r26, 0 (r27) # Set write flag.

	lis r23, 0x1000
	li r22, 0

	cmplw r26, r23
	bge DecodeCodeType_MemoryFill_Data

DecodeCodeType_MemoryFill_Code:
	add r3, r26, r22
	cmplw r3, r23
	bge DecodeCodeType_Exit

	mr r4, r25
	bl InstructionPatcher

	addi r22, r22, 0x4
	cmpw r22, r24
	blt DecodeCodeType_MemoryFill_Code
	b DecodeCodeType_Exit

DecodeCodeType_MemoryFill_Data:
	stwx r25, r26, r22

	addi r22, r22, 0x4
	cmpw r22, r24
	blt DecodeCodeType_MemoryFill_Data
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                             Memory Copy [21]
#! ------------------------------------------------------------------------
DecodeCodeType_MemoryCopy:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	lwz r26, 0x8 (r31) # Address LLLLLLLL or signed volatile offset KKKKKKKK.

	ROUND_UP_TO_ALIGNED r26

	lwz r25, 0x4 (r31) # Address EEEEEEEE or signed volatile offset KKKKKKKK.

	ROUND_UP_TO_ALIGNED r25

	lwz r24, 0xC (r31) # Range MMMMMMMM.

	ROUND_UP_TO_ALIGNED r24

	beq DecodeCodeType_MemoryCopy_General
	lwz r12, 0 (r28) # Computed pointer.
	add r26, r26, r12

DecodeCodeType_MemoryCopy_General:
	addi r31, r31, 0x10

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	mr r3, r26 # Check start address.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	add r3, r26, r24
	subi r3, r3, 0x4 # Check end address.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r26, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_Exit

	lwz r5, 0 (r27) # Get write flag.
	cmpw r5, r26
	beq+ DecodeCodeType_Exit
	stw r26, 0 (r27) # Set write flag.

	cmplwi r0, 0x1000
	bge DecodeCodeType_MemoryCopy_Data

DecodeCodeType_MemoryCopy_Code:
	mr r3, r26
	mr r4, r25
	mr r5, r24
	bl KernelCopyData

	b DecodeCodeType_Exit

DecodeCodeType_MemoryCopy_Data:
	mr r3, r26
	mr r4, r25
	mr r5, r24
	bl memcpy

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                            Load Pointer [30]
#! ------------------------------------------------------------------------
DecodeCodeType_DereferencePointer:
	lbz r5, 0x1 (r31)
	rlwinm. r0, r5, 28, 28, 31 # Extract "isPointer" bits.
	lwz r26, 0x4 (r31) # Address LLLLLLLL or signed offset KKKKKKKK.
	lwz r25, 0x8 (r31) # RANGE_ST.
	lwz r24, 0xC (r31) # RANGE_EN.
	beq DecodeCodeType_DereferencePointer_General
	lwz r12, 0 (r28) # Read computed pointer.
	add r26, r26, r12

DecodeCodeType_DereferencePointer_General:
	addi r31, r31, 0x10

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	mr r3, r26
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_DereferencePointer_UpdateFlag

	srwi r0, r26, 16
	cmplwi r0, 0x5000 # Make sure target address is safe.
	bge DecodeCodeType_DereferencePointer_UpdateFlag

	lwz r23, 0 (r26)

	mr r3, r23
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_DereferencePointer_UpdateFlag

	cmplw r23, r25
	blt DecodeCodeType_DereferencePointer_UpdateFlag
	cmplw r23, r24
	bgt DecodeCodeType_DereferencePointer_UpdateFlag

	stw r23, 0 (r28) # Store computed pointer.
	b DecodeCodeType_Exit

DecodeCodeType_DereferencePointer_UpdateFlag:
	li r5, 0x7FFF
	addi r6, r5, 0x3FFF
	sth r5, 0x0 (r29)
	sth r6, 0x2 (r29)
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                         Pointer Offset Modifier
#! ------------------------------------------------------------------------
DecodeCodeType_PtrOffsetModfier:
	lwz r6, 0x4 (r31) # Non-volatile signed offset QQQQQQQQ.
	lbz r7, 0x2 (r31) # Integer register "R".
	lwz r12, 0 (r28) # Computed pointer.

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_NoOperation

	clrlwi r7, r7, 29
	slwi r7, r7, 2
	lwzx r7, r26, r7 # Integer register "R" value.

	cmpwi r5, 0x31
	beq DecodeCodeType_PtrOffsetModfier_Add
	cmpwi r5, 0x32
	beq DecodeCodeType_PtrOffsetModfier_AddIndexed
	cmpwi r5, 0x33
	beq DecodeCodeType_PtrOffsetModfier_Sub
	cmpwi r5, 0x34
	beq DecodeCodeType_PtrOffsetModfier_SubIndexed
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                    Add Offset To Pointer Indexed [32]
#! ------------------------------------------------------------------------
DecodeCodeType_PtrOffsetModfier_AddIndexed:
	add r6, r6, r7

#! ------------------------------------------------------------------------
#!                        Add Offset To Pointer [31]
#! ------------------------------------------------------------------------
DecodeCodeType_PtrOffsetModfier_Add:
	add r12, r12, r6
	b DecodeCodeType_PtrOffsetModfier_UpdatePtr

#! ------------------------------------------------------------------------
#!                 Subtract Offset To Pointer Indexed [34]
#! ------------------------------------------------------------------------
DecodeCodeType_PtrOffsetModfier_SubIndexed:
	add r6, r6, r7

#! ------------------------------------------------------------------------
#!                    Subtract Offset To Pointer [33]
#! ------------------------------------------------------------------------
DecodeCodeType_PtrOffsetModfier_Sub:
	sub r12, r12, r6

DecodeCodeType_PtrOffsetModfier_UpdatePtr:
	stw r12, 0 (r28) # Update computed pointer.
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                                Loop [80]
#! ------------------------------------------------------------------------
#! ------------------------------------------------------------------------
#!                            Loop Indexed [81]
#! ------------------------------------------------------------------------
DecodeCodeType_Loop:
	lwz r6, 0 (r29) # Get conditional flags.
	clrlwi r0, r6, 16
	cmpwi r0, 0
	beq DecodeCodeType_CalcLoop

	li r5, 0
	b DecodeCodeType_SetIdentifier

DecodeCodeType_CalcLoop:
	lwz r7, 0 (r27) # Check conditional flags backup.
	cmpwi r7, 0
	bne DecodeCodeType_Loop_SetFlags
	stw r6, 0 (r27) # Backup the conditional flags.
	mr r7, r6

DecodeCodeType_Loop_SetFlags:
	stw r7, 0 (r27) # Restore the conditional flags.

DecodeCodeType_SetIdentifier:
	stb r5, 0x4 (r27) # Set code type identifier.
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                             Break Loop [82]
#! ------------------------------------------------------------------------
DecodeCodeType_BreakLoop:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_NoOperation

	li r5, -1

	lis r12, "CODE_HANDLER_0x80_CODETYPE_FLAG"@ha
	stw r5, "CODE_HANDLER_0x80_CODETYPE_FLAG"@l (r12)
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                             Execute ASM [C0]
#! ------------------------------------------------------------------------
DecodeCodeType_ExecuteASM:
	lhz r5, 0x2 (r31) # Amount of code lines NNNN.
	mulli r5, r5, 0x8
	addi r12, r31, 0x4 # Where code execution will resume.

	addi r5, r5, 0x8 # Include the initial codeline.
	add r31, r31, r5
	cmpw r31, r30 # Check available space.
	blt+ DecodeCodeType_ExcuteASM_General
	mr r31, r30
	b DecodeCodeType_Exit

DecodeCodeType_ExcuteASM_General:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	lswi r3, r26, 0x20
	lfs f1, 0x20 (r26)
	lfs f2, 0x24 (r26)
	lfs f3, 0x28 (r26)
	lfs f4, 0x2C (r26)
	lfs f5, 0x30 (r26)
	lfs f6, 0x34 (r26)
	lfs f7, 0x38 (r26)
	lfs f8, 0x3C (r26)

	stfd f31, 0x11C (r1)
	ps_merge10 f31, f31, f31
	stfs f31, 0x124 (r1)
	stfd f30, 0x110 (r1)
	ps_merge10 f30, f30, f30
	stfs f30, 0x118 (r1)
	stfd f29, 0x104 (r1)
	ps_merge10 f29, f29, f29
	stfs f29, 0x10C (r1)
	stfd f28, 0xF8 (r1)
	ps_merge10 f28, f28, f28
	stfs f28, 0x100 (r1)
	stfd f27, 0xEC (r1)
	ps_merge10 f27, f27, f27
	stfs f27, 0xF4 (r1)
	stfd f26, 0xE0 (r1)
	ps_merge10 f26, f26, f26
	stfs f26, 0xE8 (r1)
	stfd f25, 0xD4 (r1)
	ps_merge10 f25, f25, f25
	stfs f25, 0xDC (r1)
	stfd f24, 0xC8 (r1)
	ps_merge10 f24, f24, f24
	stfs f24, 0xD0 (r1)
	stfd f23, 0xBC (r1)
	ps_merge10 f23, f23, f23
	stfs f23, 0xC4 (r1)
	stfd f22, 0xB0 (r1)
	ps_merge10 f22, f22, f22
	stfs f22, 0xB8 (r1)
	stfd f21, 0xA4 (r1)
	ps_merge10 f21, f21, f21
	stfs f21, 0xAC (r1)
	stfd f20, 0x98 (r1)
	ps_merge10 f20, f20, f20
	stfs f20, 0xA0 (r1)
	stfd f19, 0x8C (r1)
	ps_merge10 f19, f19, f19
	stfs f19, 0x94 (r1)
	stfd f18, 0x80 (r1)
	ps_merge10 f18, f18, f18
	stfs f18, 0x88 (r1)
	stfd f17, 0x74 (r1)
	ps_merge10 f17, f17, f17
	stfs f17, 0x7C (r1)
	stfd f16, 0x68 (r1)
	ps_merge10 f16, f16, f16
	stfs f16, 0x70 (r1)
	stfd f15, 0x5C (r1)
	ps_merge10 f15, f15, f15
	stfs f15, 0x64 (r1)
	stfd f14, 0x50 (r1)
	ps_merge10 f14, f14, f14
	stfs f14, 0x58 (r1)
	stmw r14, 0x8 (r1)

	mtctr r12
	bctrl # Run user code.

	lmw r14, 0x8 (r1)
	lfs f14, 0x58 (r1)
	lfs f15, 0x64 (r1)
	lfs f16, 0x70 (r1)
	lfs f17, 0x7C (r1)
	lfs f18, 0x88 (r1)
	lfs f19, 0x94 (r1)
	lfs f20, 0xA0 (r1)
	lfs f21, 0xAC (r1)
	lfs f22, 0xB8 (r1)
	lfs f23, 0xC4 (r1)
	lfs f24, 0xD0 (r1)
	lfs f25, 0xDC (r1)
	lfs f26, 0xE8 (r1)
	lfs f27, 0xF4 (r1)
	lfs f28, 0x100 (r1)
	lfs f29, 0x10C (r1)
	lfs f30, 0x118 (r1)
	lfs f31, 0x124 (r1)
	lfd f14, 0x50 (r1)
	lfd f15, 0x5C (r1)
	lfd f16, 0x68 (r1)
	lfd f17, 0x74 (r1)
	lfd f18, 0x80 (r1)
	lfd f19, 0x8C (r1)
	lfd f20, 0x98 (r1)
	lfd f21, 0xA4 (r1)
	lfd f22, 0xB0 (r1)
	lfd f23, 0xBC (r1)
	lfd f24, 0xC8 (r1)
	lfd f25, 0xD4 (r1)
	lfd f26, 0xE0 (r1)
	lfd f27, 0xEC (r1)
	lfd f28, 0xF8 (r1)
	lfd f29, 0x104 (r1)
	lfd f30, 0x110 (r1)
	lfd f31, 0x11C (r1)

	stswi r3, r26, 0x8
	stfs f1, 0x20 (r26)
	stfs f2, 0x24 (r26)
	stfs f3, 0x28 (r26)
	stfs f4, 0x2C (r26)
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                     System- And Procedure Calls [C1]
#! ------------------------------------------------------------------------
DecodeCodeType_ProcedureAndSyscalls:
	lhz r5, 0x2 (r29) # Check conditional flag.
	cmpwi r5, 0
	bne DecodeCodeType_NoOperation

	lhz r0, 0x2 (r31) # Syscall value.
	lwz r25, 0x4 (r31) # Procedure call address.

	ROUND_UP_TO_ALIGNED r25

	cmpwi r0, 0
	beq DecodeCodeType_ProcedureAndSyscalls_RunProcedure
	lis r6, 0
	ori r6, r6, 0x8500
	cmplw r0, r6
	bge DecodeCodeType_NoOperation

	lswi r3, r26, 0x20
	lfs f1, 0x20 (r26)
	lfs f2, 0x24 (r26)
	lfs f3, 0x28 (r26)
	lfs f4, 0x2C (r26)
	lfs f5, 0x30 (r26)
	lfs f6, 0x34 (r26)
	lfs f7, 0x38 (r26)
	lfs f8, 0x3C (r26)

	sc 0x0 # Run syscall.
	nop
	b DecodeCodeType_ProcedureAndSyscalls_Return

DecodeCodeType_ProcedureAndSyscalls_RunProcedure:
	mr r3, r25
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_NoOperation

	srwi r0, r25, 16
	cmplwi r0, 0x1000 # Make sure target address is safe.
	bge DecodeCodeType_NoOperation

	lswi r3, r26, 0x20
	lfs f1, 0x20 (r26)
	lfs f2, 0x24 (r26)
	lfs f3, 0x28 (r26)
	lfs f4, 0x2C (r26)
	lfs f5, 0x30 (r26)
	lfs f6, 0x34 (r26)
	lfs f7, 0x38 (r26)
	lfs f8, 0x3C (r26)

	mtctr r25
	bctrl # Run procedure.

DecodeCodeType_ProcedureAndSyscalls_Return:
	stswi r3, r26, 0x8
	stfs f1, 0x20 (r26)
	stfs f2, 0x24 (r26)
	stfs f3, 0x28 (r26)
	stfs f4, 0x2C (r26)
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                                Insert ASM
#! ------------------------------------------------------------------------
DecodeCodeType_InsertASM:
	lwz r26, 0x4 (r31) # Address LLLLLLLL.

	ROUND_UP_TO_ALIGNED r26

	addi r25, r31, 0x8 # Machine code start. (XXXXXXXX...)
	clrlwi r24, r5, 28

	lhz r5, 0x2 (r31) # Amount of code lines NNNN.
	cmpwi r5, 0
	beq DecodeCodeType_NoOperation

	mulli r5, r5, 0x8
	addi r5, r5, 0x8 # Include the initial codeline.
	add r31, r31, r5
	cmpw r31, r30 # Check available space.
	blt+ DecodeCodeType_InsertASM_General
	mr r31, r30
	b DecodeCodeType_Exit

DecodeCodeType_InsertASM_General:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	lhz r5, 0 (r27) # Get write flag.
	subic. r5, r5, 0x1
	bge+ DecodeCodeType_Exit
	sth r5, 0 (r27) # Set write flag.

	mr r3, r26 # Check if address is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r26, 16
	cmplwi r0, 0x1000 # Make sure target address is safe.
	bge DecodeCodeType_Exit

	cmpwi r24, 0x2
	beq DecodeCodeType_InsertASM_ViaLR
	cmpwi r24, 0x3
	beq DecodeCodeType_InsertASM_ViaCTR
	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                          Insert ASM Via LR [C2]
#! ------------------------------------------------------------------------
DecodeCodeType_InsertASM_ViaLR:
	li r4, 0x3
	b DecodeCodeType_InsertASM_PatchTarget

#! ------------------------------------------------------------------------
#!                         Insert ASM Via CTR [C3]
#! ------------------------------------------------------------------------
DecodeCodeType_InsertASM_ViaCTR:
	li r4, 0x2

DecodeCodeType_InsertASM_PatchTarget:
	oris r4, r4, 0x4800 # Branch PowerPC instruction
	rlwimi r4, r25, 0, 6, 29 # Insert address to branch. Special thanks to ShyGuy for the original implementation.
	mr r3, r26
	bl InstructionPatcher

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                          ASM String Writes [C4]
#! ------------------------------------------------------------------------
DecodeCodeType_ASMStringWrites:
	lwz r26, 0x4 (r31) # Address LLLLLLLL.

	ROUND_UP_TO_ALIGNED r26

	addi r25, r31, 0x8 # Machine code XXXXXXXX...

	lhz r5, 0x2 (r31) # Amount of code lines NNNN.
	cmpwi r5, 0
	beq DecodeCodeType_NoOperation

	mulli r24, r5, 0x8
	addi r5, r24, 0x8 # Include the initial codeline.
	add r31, r31, r5
	cmpw r31, r30 # Check available space.
	blt+ DecodeCodeType_ASMStringWrites_General
	mr r31, r30
	b DecodeCodeType_Exit

DecodeCodeType_ASMStringWrites_General:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_Exit

	lhz r5, 0 (r27) # Get write flag.
	subic. r5, r5, 0x1
	bge+ DecodeCodeType_Exit
	sth r5, 0 (r27) # Set write flag.

	mr r3, r26 # Check if address is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r26, 16
	cmplwi r0, 0x1000 # Make sure target address is safe.
	bge DecodeCodeType_Exit

	li r5, -0x4

DecodeCodeType_ASMStringWrites_CalcLength:
	addi r5, r5, 0x4
	lwzx r6, r25, r5

	cmplw r5, r24
	bge DecodeCodeType_ASMStringWrites_Patch

	cmpwi r6, 0
	bne DecodeCodeType_ASMStringWrites_CalcLength

DecodeCodeType_ASMStringWrites_Patch:
	mr r3, r26
	mr r4, r25
	bl KernelCopyData

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                             Terminator [D0]
#! ------------------------------------------------------------------------
DecodeCodeType_Terminator:
	li r0, 0
	stw r0, 0 (r28) # Reset computed pointer.
	stw r0, 0 (r29) # Reset conditional flag and counter.
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                           Loop Terminator [D1]
#! ------------------------------------------------------------------------
DecodeCodeType_LoopTerminator:
	SET_ADDR r11, "CODE_HANDLER_0x80_CODETYPE_FLAG"
	stb r5, 0x4 (r27) # Set code type identifier.
	li r7, 0
	li r8, 0

DecodeCodeType_LoopTerminator_FindLoopStart:
	subi r8, r8, 0x8 # Go to previous potential code type specific data.
	add r12, r27, r8
	lbz r5, 0x4 (r12)
	cmpwi r5, 0xD1
	beq DecodeCodeType_NoOperation
	ori r5, r5, 0x1
	cmpwi r5, 0x81
	beq DecodeCodeType_LoopTerminator_AttemptLoop

	cmpw r12, r6 # Check if loop finder is still in range.
	blt DecodeCodeType_NoOperation

	b DecodeCodeType_LoopTerminator_FindLoopStart

DecodeCodeType_LoopTerminator_AttemptLoop:
	add r12, r31, r8 # Found loop conditional.

	lbz r5, 0 (r12) # Get code type identifier.
	cmpwi r5, 0x80
	beq DecodeCodeType_LoopTerminator_Loop
	cmpwi r5, 0x81
	beq DecodeCodeType_LoopTerminator_LoopIndexed
	b DecodeCodeType_NoOperation

DecodeCodeType_LoopTerminator_Loop:
	lwz r5, 0x4 (r12) # Get NNNNNNNN.
	b DecodeCodeType_LoopTerminator_General

DecodeCodeType_LoopTerminator_LoopIndexed:
	lbz r5, 0x2 (r12) # Get integer register "R".
	clrlwi r5, r5, 29
	slwi r5, r5, 2

	lwzx r5, r26, r5 # Get integer register "R" value.

DecodeCodeType_LoopTerminator_General:
	lwz r6, 0 (r11) # Current loop.
	cmplw r6, r5
	addi r6, r6, 0x1
	stw r6, 0 (r11) # Update loop.
	bge DecodeCodeType_LoopTerminator_Terminate

	lwzx r0, r27, r8
	stw r0, 0 (r29) # Restore conditional flags to what they were.

	mr r31, r12
	b DecodeCodeType_Exit

DecodeCodeType_LoopTerminator_Terminate:
	li r0, 0
	stw r0, 0 (r11)
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                       Conditional Terminator [D2]
#! ------------------------------------------------------------------------
DecodeCodeType_ConditionalTerminator:
	lhz r5, 0 (r29) # Conditional counter.
	lhz r6, 0x2 (r29) # Conditional flag.
	cmpwi r5, 0
	beq DecodeCodeType_NoOperation
	cmpw r5, r6
	subi r5, r5, 0x1
	sth r5, 0 (r29) # Update conditional counter.
	bne DecodeCodeType_NoOperation
	li r6, 0
	sth r6, 0x2 (r29) # Update conditional flag.
	b DecodeCodeType_NoOperation

#! ------------------------------------------------------------------------
#!                       Display Message And Halt [E0]
#! ------------------------------------------------------------------------
DecodeCodeType_DisplayMessageAndPause:
	addi r3, r31, 0x8
	lwz r4, 0x4 (r31)
	li r5, 0

DecodeCodeType_DisplayMessageAndPause_CalcSize:
	lbzx r0, r3, r5
	addi r5, r5, 0x1
	cmpwi r0, 0
	bne DecodeCodeType_DisplayMessageAndPause_CalcSize

	li r6, 0x8
	divw r6, r5, r6 # Get number of whole codelines.
	andi. r0, r5, 0x7 # Modulo.
	beq DecodeCodeType_DisplayMessageAndPause_CalcCCSize
	addi r6, r6, 0x1 # Round up towards next 0x8.

DecodeCodeType_DisplayMessageAndPause_CalcCCSize:
	mulli r6, r6, 0x8
	addi r6, r6, 0x8 # Include the initial codeline.
	add r31, r31, r6
	cmpw r31, r30 # Check available space.
	blt+ DecodeCodeType_DisplayMessageAndPause_General
	mr r31, r30
	b DecodeCodeType_Exit

DecodeCodeType_DisplayMessageAndPause_General:
	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	lhz r5, 0 (r27) # Get write flag.
	subic. r5, r5, 0x1
	bge+ DecodeCodeType_Exit
	sth r5, 0 (r27) # Set write flag.

	slwi r4, r4, 0x8
	bl DisplayMessage

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                  Display Pointer Message And Halt [E1]
#! ------------------------------------------------------------------------
DecodeCodeType_DisplayPointerMessageAndPause:
	lwz r5, 0x4 (r31)
	addi r31, r31, 0x8
	lwz r25, 0 (r28) # Computed pointer.
	slwi r26, r5, 0x8 # Color RRGGBB.

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	mr r3, r25
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r25, 16
	cmplwi r0, 0x5000 # Make sure end address is safe.
	bge DecodeCodeType_Exit

	lhz r5, 0 (r27) # Get write flag.
	subic. r5, r5, 0x1
	bge+ DecodeCodeType_Exit
	sth r5, 0 (r27) # Set write flag.

	mr r3, r25
	mr r4, r26
	bl DisplayMessage

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                      Clear Message And Resume [E2]
#! ------------------------------------------------------------------------
DecodeCodeType_ClearMessageAndResume:
	addi r31, r31, 0x8

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	lhz r5, 0 (r27) # Get write flag.
	subic. r5, r5, 0x1
	bge+ DecodeCodeType_Exit
	sth r5, 0 (r27) # Set write flag.

	lis r3, "AVMGetDRCScanMode_Ptr"@ha
	lwz r3, "AVMGetDRCScanMode_Ptr"@l (r3)
	addi r3, r3, 0x44
	lis r4, 0x3800 # Equivalent to PPC instruction "li r0, 0".
	bl InstructionPatcher

	li r3, "SCREEN_TV"
	bl DCUpdate

	li r3, "SCREEN_DRC"
	bl DCUpdate

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                              Corruptor [F0]
#! ------------------------------------------------------------------------
DecodeCodeType_Corruptor:
	addi r12, r31, 0x4
	lswi r23, r12, 0x10 # Load all parameters.

	addi r31, r31, 0x18

	lhz r0, 0x2 (r29) # Check conditional flag.
	cmpwi r0, 0
	bne DecodeCodeType_ResetWriteFlagAndExit

	lhz r5, 0 (r27) # Get write flag.
	subic. r5, r5, 0x1
	bge+ DecodeCodeType_Exit
	sth r5, 0 (r27) # Set write flag.

	mr r3, r23 # Check if start address LLLLLLLL is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r23, 16
	cmplwi r0, 0x5000 # Make sure start address is safe.
	bge DecodeCodeType_Exit

	mr r3, r24 # Check if end address EEEEEEEE is safe.
	bl OSIsAddressValid
	cmpwi r3, 0
	beq DecodeCodeType_Exit

	srwi r0, r24, 16
	cmplwi r0, 0x5000 # Make sure end address is safe.
	bge DecodeCodeType_Exit

	li r22, 0
	sub. r24, r24, r23
	blt DecodeCodeType_Exit

DecodeCodeType_Corruptor_AttemptWrites:
	lwzx r5, r23, r22

	cmpw r5, r25 # Check if current address has VVVVVVVV.
	bne DecodeCodeType_Corruptor_TryNextAttempt

	add r3, r23, r22
	mr r4, r26 # Store value WWWWWWWW.
	bl InstructionPatcher

DecodeCodeType_Corruptor_TryNextAttempt:
	addi r22, r22, 0x4
	cmplw r22, r24
	blt DecodeCodeType_Corruptor_AttemptWrites

	b DecodeCodeType_Exit

#! ------------------------------------------------------------------------
#!                            No Operation [CC]
#! ------------------------------------------------------------------------
DecodeCodeType_NoOperation:
	addi r31, r31, 0x8
	b DecodeCodeType_Exit

DecodeCodeType_ResetWriteFlagAndExit:
	li r0, 0
	sth r0, 0 (r27) # Set write flag.

DecodeCodeType_Exit:
	mr r3, r31
	lmw r20, 0x128 (r1)
	isync
	lwz r0, 0x15C (r1)
	mtlr r0
	addi r1, r1, 0x158
	blr

/**========================================================================
 **                             DisplayMessage
 *?  Similar to OSPanic, but allows changing background color and doesn't
 *?  crash the system.
 *@param1 r3 "string" address
 *@param2 r4 "color" RRGGBB00
 *========================================================================**/
DisplayMessage:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0x18 (r1)
	stmw r28, 0x8 (r1)

	mr r31, r3
	mr r30, r4

	bl OSScreenInit

	li r3, "SCREEN_TV"
	bl OSScreenGetBufferSizeEx
	mr r29, r3

	li r3, "SCREEN_DRC"
	bl OSScreenGetBufferSizeEx
	add r3, r29, r3
	li r4, 0x100
	bl MEMAllocFromDefaultHeapEx
	mr. r28, r3
	beq DisplayMessage_Failure

	li r3, "SCREEN_TV"
	mr r4, r28
	bl OSScreenSetBufferEx

	li r3, "SCREEN_DRC"
	add r4, r28, r29
	bl OSScreenSetBufferEx

	li r3, "SCREEN_TV"
	li r4, 1
	bl OSScreenEnableEx

	li r3, "SCREEN_DRC"
	li r4, 1
	bl OSScreenEnableEx

	li r3, "SCREEN_TV"
	mr r4, r30
	bl OSScreenClearBufferEx

	li r3, "SCREEN_DRC"
	mr r4, r30
	bl OSScreenClearBufferEx

	li r3, "SCREEN_TV"
	li r4, 0
	li r5, 0
	mr r6, r31
	bl OSScreenPutFontEx

	li r3, "SCREEN_DRC"
	li r4, 0
	li r5, 0
	mr r6, r31
	bl OSScreenPutFontEx

	li r3, "SCREEN_TV"
	bl OSScreenFlipBuffersEx

	li r3, "SCREEN_DRC"
	bl OSScreenFlipBuffersEx

	lis r3, "AVMGetDRCScanMode_Ptr"@ha
	lwz r3, "AVMGetDRCScanMode_Ptr"@l (r3)
	addi r3, r3, 0x44
	lis r4, 0x3800
	ori r4, r4, 0x0001 # Equivalent to PPC instruction "li r0, 1"
	bl InstructionPatcher

	mr r3, r28
	bl MEMFreeToDefaultHeap

	b DisplayMessage_Exit

DisplayMessage_Failure:
	li r3, "SCREEN_TV"
	bl DCUpdate

	li r3, "SCREEN_DRC"
	bl DCUpdate

DisplayMessage_Exit:
	lmw r28, 0x8 (r1)
	lwz r0, 0x1C (r1)
	mtlr r0
	addi r1, r1, 0x18
	blr

/**========================================================================
 **                            DecodeListClear
 *?  Clears various memory locations used by DecodeCodeType.
 *========================================================================**/
DecodeListClear:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0x8 (r1)

	li r11, 0

	lis r12, "CODE_HANDLER_CONDITIONAL_FLAG"@ha
	stw r11, "CODE_HANDLER_CONDITIONAL_FLAG"@l (r12)

	lis r12, "CODE_HANDLER_COMPUTED_POINTER"@ha
	stw r11, "CODE_HANDLER_COMPUTED_POINTER"@l (r12)

	lis r12, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@ha
	stw r11, "CODE_HANDLER_0x0C_CODETYPE_POINTER"@l (r12)

	lis r12, "CODE_HANDLER_0x80_CODETYPE_FLAG"@ha
	stw r11, "CODE_HANDLER_0x80_CODETYPE_FLAG"@l (r12)

	SET_ADDR r3, "CONTROLLER_STATUS_BUFFERS"

	li r4, 0
	li r5, 0x480
	bl OSBlockSet

	SET_ADDR r3, "CODE_HANDLER_PSEUDO_REGISTERS"

	li r4, 0
	li r5, 0x40
	bl OSBlockSet

	SET_ADDR r3, "CODE_HANDLER_RESERVED_DATA"

	li r4, 0
	lis r5, "CODE_LIST_LENGTH"@h
	ori r5, r5, "CODE_LIST_LENGTH"@l
	bl OSBlockSet

	lwz r0, 0xC (r1)
	mtlr r0
	addi r1, r1, 0x8
	blr

/**========================================================================
 **                             KernelCopyData
 *?  Similar to "memcpy" however this allows memory writes in the code
 *?  region as well. Usage of this function in data sections is
 *?  unnecessary and may cause an adverse performance impact.
 *@param1 r3 "target" address
 *@param2 r4 "source" address
 *@param3 r5 "length" unsigned int
 *========================================================================**/
KernelCopyData:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0x18 (r1)
	stmw r28, 0x8 (r1)

	mr r31, r3
	mr r30, r4
	mr r29, r5

	mr r4, r5
	bl DCFlushRange

	mr r3, r30
	bl OSEffectiveToPhysical
	mr r28, r3

	mr r3, r31
	bl OSEffectiveToPhysical

	mr r4, r28
	mr r5, r29
	li r0, "SC0x25_KernelCopyData"
	sc
	nop

	lmw r28, 0x8 (r1)
	lwz r0, 0x1C (r1)
	mtlr r0
	addi r1, r1, 0x18
	blr

/**========================================================================
 **                           InstructionPatcher
 *?  Replaces an instruction in the code region with a specified value.
 *@param1 r3 "target" address
 *@param2 r4 "instruction" unsigned int
 *========================================================================**/
InstructionPatcher:
	mflr r0
	stw r0, 0x4 (r1)
	stwu r1, -0xC (r1)

	addi r12, r1, 0x8

	stw r4, 0 (r12)

	FLUSH_DATA_BLOCK r12

	mr r4, r12
	li r5, 0x4
	bl KernelCopyData

	lwz r0, 0x10 (r1)
	mtlr r0
	addi r1, r1, 0xC
	blr

/**========================================================================
 **                           OSDynLoad_Acquire
 *?  Load a module. If the module is already loaded, increase reference
 *?  count. 
 *@param1 r3 "module name" address
 *@param2 r4 "output location" address
 *========================================================================**/
OSDynLoad_Acquire:
	GOTO_EXPORT_FUNC "addr_OSDynLoad_Acquire"

/**========================================================================
 **                          OSDynLoad_FindExport
 *?  Retrieve the address of a function or data export from a module.
 *?  For "@param2" use:
 **  0x00000000: (Function)
 **  0x00000001: (Data)
 *@param1 r3 "module" unsigned int
 *@param2 r4 "export type" unsigned int
 *@param3 r5 "name" address
 *@param4 r6 "output location" address
 *========================================================================**/
OSDynLoad_FindExport:
	GOTO_EXPORT_FUNC "addr_OSDynLoad_FindExport"

/**========================================================================
 **                           OSIsAddressValid
 *?  Checks whether a virtual memory address is readable or not.
 *@param1 r3 "virtual address" address
 *@return r3 "IsAddressValid" boolean
 *========================================================================**/
OSIsAddressValid:
	GOTO_EXPORT_FUNC "OSIsAddressValid_Ptr"

/**========================================================================
 **                                 memcpy
 *?  Moves chunks of memory around. Overlapping source and destination
 *?  regions are supported. This flushes the data caches for the source
 *?  and destination.
 *@param1 r3 "target" address
 *@param2 r4 "source" address
 *@param3 r5 "length" unsigned int
 *@return r3 "target" address
 *========================================================================**/
memcpy:
	GOTO_EXPORT_FUNC "memcpy_Ptr"

/**========================================================================
 **                               OSBlockSet
 *?  Fills a chunk of memory with the given value.
 *@param1 r3 "target" address
 *@param2 r4 "value" unsigned int
 *@param3 r5 "length" unsigned int
 *@return r3 "target" address
 *========================================================================**/
OSBlockSet:
	GOTO_EXPORT_FUNC "OSBlockSet_Ptr"

/**========================================================================
 **                              DCFlushRange
 *?  Flushes any recently cached data into main memory. It also invalidates
 *?  cached data. "range" will be rounded up to the next 0x20.
 *?  Unnecessary use of caching functions can have an adverse performance
 *?  impact.
 *@param1 r3 "target" address
 *@param3 r4 "range" unsigned int
 *========================================================================**/
DCFlushRange:
	GOTO_EXPORT_FUNC "DCFlushRange_Ptr"

/**========================================================================
 **                         OSEffectiveToPhysical
 *?  Converts a virtual address to its physical representation.
 *@param1 r3 "virtual address" address
 *@return r3 "physical address" unsigned int
 *========================================================================**/
OSEffectiveToPhysical:
	GOTO_EXPORT_FUNC "OSEffectiveToPhysical_Ptr"

/**========================================================================
 **                              OSScreenInit
 *?  Initialises the OSScreen library for use. This function must be called
 *?  before using any other OSScreen functions.
 *========================================================================**/
OSScreenInit:
	GOTO_EXPORT_FUNC "OSScreenInit_Ptr"

/**========================================================================
 **                        OSScreenGetBufferSizeEx
 *?  Gets the amount of memory required to fit both buffers of a given
 *?  screen.
 *?  For "@param1" use:
 **  0x00000000: SCREEN_TV
 **  0x00000001: SCREEN_DRC
 *@param1 r3 "OSScreenID" ID
 *========================================================================**/
OSScreenGetBufferSizeEx:
	GOTO_EXPORT_FUNC "OSScreenGetBufferSizeEx_Ptr"

/**========================================================================
 **                          OSScreenSetBufferEx
 *?  Sets the memory location for both buffers of a given screen.
 *?  This location must be of the size prescribed by
 *?  "OSScreenGetBufferSizeEx" and at an address aligned to 0x100 bytes.
 *?  For "@param1" use:
 **  0x00000000: SCREEN_TV
 **  0x00000001: SCREEN_DRC
 *@param1 r3 "OSScreenID" ID
 *@param2 r4 "SetBuffer" address
 *========================================================================**/
OSScreenSetBufferEx:
	GOTO_EXPORT_FUNC "OSScreenSetBufferEx_Ptr"

/**========================================================================
 **                            OSScreenEnableEx
 *?  Enables or disables a given screen.
 *?  If a screen is disabled, it shows black.
 *?  For "@param1" use:
 **  0x00000000: SCREEN_TV
 **  0x00000001: SCREEN_DRC
 *@param1 r3 "OSScreenID" ID
 *@param2 r4 "Enable" Boolean
 *========================================================================**/
OSScreenEnableEx:
	GOTO_EXPORT_FUNC "OSScreenEnableEx_Ptr"

/**========================================================================
 **                         OSScreenClearBufferEx
 *?  Clear the work buffer of the given screen by setting all of its pixels
 *?  to a given colour. 
 *?  For "@param1" use:
 **  0x00000000: SCREEN_TV
 **  0x00000001: SCREEN_DRC
 *@param1 r3 "OSScreenID" ID
 *@param2 r4 "Color" RRGGBB00
 *========================================================================**/
OSScreenClearBufferEx:
	GOTO_EXPORT_FUNC "OSScreenClearBufferEx_Ptr"

/**========================================================================
 **                           OSScreenPutFontEx
 *?  Draws text at the given position. The text will be drawn to the work
 *?  buffer with a built-in monospace font, coloured white, and
 *?  anti-aliased. The position coordinates are in characters, not pixels.
 *?  For "@param1" use:
 **  0x00000000: SCREEN_TV
 **  0x00000001: SCREEN_DRC
 *?  For "@param4" string is null-terminated.
 *@param1 r3 "OSScreenID" ID
 *@param2 r4 "row" unsigned int
 *@param3 r5 "column" unsigned int
 *@param4 r6 "string" address
 *========================================================================**/
OSScreenPutFontEx:
	GOTO_EXPORT_FUNC "OSScreenPutFontEx_Ptr"

/**========================================================================
 **                         OSScreenFlipBuffersEx
 *?  Swap the buffers of the given screen. The work buffer will become the
 *?  visible buffer and will start being shown on-screen, while the visible
 *?  buffer becomes the new work buffer. This operation is known as
 *?  "flipping" the buffers. You must call this function once drawing is
 *?  complete, otherwise draws will not appear on-screen.
 *?  For "@param1" use:
 **  0x00000000: SCREEN_TV
 **  0x00000001: SCREEN_DRC
 *@param1 r3 "OSScreenID" ID
 *========================================================================**/
OSScreenFlipBuffersEx:
	GOTO_EXPORT_FUNC "OSScreenFlipBuffersEx_Ptr"

/**========================================================================
 **                                VPADInit
 *?  Initialises the VPAD library for use.
 *?  As of Cafe OS 5.5.x (OSv10 v15702) this function simply logs a
 *?  deprecation message and returns. However, this may not be the case on
 *?  older versions.
 *========================================================================**/
VPADInit:
	GOTO_EXPORT_FUNC "VPADInit_Ptr"

/**========================================================================
 **                                VPADRead
 *?  Read controller data from the desired Gamepad.
 *?  For "@param1" use 0x0, retail Wii U systems have a single Gamepad.
 *?  For "@param2" requires 0xAC (172) bytes.
 *?  For "@param3" set the desired amount of VPAD Status arrays to store.
 *?  For "@param4", these are the possible values that it will output:
 **  0x00000000: VPAD_READ_SUCCESS
 **  0xFFFFFFFF: VPAD_READ_NO_SAMPLES
 **  0xFFFFFFFE: VPAD_READ_INVALID_CONTROLLER
 **  0xFFFFFFFC: VPAD_READ_BUSY
 **  0xFFFFFFFB: VPAD_READ_UNINITIALIZED
 *@param1 r3 "VPAD Channel" unsigned int
 *@param2 r4 "VPAD Status" address
 *@param3 r5 "VPAD Status Count" unsigned int
 *@param4 r6 "VPAD Error Detailed" address
 *@return r3 "VPAD Error" boolean
 *========================================================================**/
VPADRead:
	GOTO_EXPORT_FUNC "VPADRead_Ptr"

/**========================================================================
 **                                KPADInit
 *?  Initialises the KPAD library for use.
 *========================================================================**/
KPADInit:
	GOTO_EXPORT_FUNC "KPADInit_Ptr"

/**========================================================================
 **                               KPADReadEx
 *?  Read data from the desired Wii Remote.
 *?  For "@param2" requires 0xF0 (240) bytes.
 *?  For "@param4", these are the possible values that it will output:
 **  0x00000000: KPAD_ERROR_OK
 **  0xFFFFFFFF: KPAD_ERROR_NO_SAMPLES
 **  0xFFFFFFFE: KPAD_ERROR_INVALID_CONTROLLER
 **  0xFFFFFFFD: KPAD_ERROR_WPAD_UNINIT
 **  0xFFFFFFFC: KPAD_ERROR_BUSY
 **  0xFFFFFFFB: KPAD_ERROR_UNINITIALIZED
 *@param1 r3 "KPAD Channel" unsigned int
 *@param2 r4 "KPAD Status" address
 *@param3 r5 "size" unsigned int
 *@param4 r6 "KPAD Error Detailed" address
 *========================================================================**/
KPADReadEx:
	GOTO_EXPORT_FUNC "KPADReadEx_Ptr"

/**========================================================================
 **                                WPADInit
 *?  Initialises the WPAD library for use.
 *========================================================================**/
WPADInit:
	GOTO_EXPORT_FUNC "WPADInit_Ptr"

/**========================================================================
 **                                DCUpdate
 *?  Updates the screen.
 *?  For "@param1" use:
 **  0x00000000: SCREEN_TV
 **  0x00000001: SCREEN_DRC
 *@param1 r3 "OSScreenID" ID
 *========================================================================**/
DCUpdate:
	GOTO_EXPORT_FUNC "DCUpdate_Ptr"

/**========================================================================
 **                       MEMAllocFromDefaultHeapEx
 *?  Allocates memory.
 *@param1 r3 "size" unsigned int
 *@param2 r4, "align" unsigned int
 *@return r3 "allocated memory" address
 *========================================================================**/
MEMAllocFromDefaultHeapEx:
	lis r12, "addr_MEMAllocFromDefaultHeapEx"@ha
	lwz r12, "addr_MEMAllocFromDefaultHeapEx"@l (r12)
	lwz r12, 0 (r12)
	mtctr r12
	bctr

/**========================================================================
 **                          MEMFreeToDefaultHeap
 *?  Frees memory.
 *@param1 r3 "allocated memory" address
 *========================================================================**/
MEMFreeToDefaultHeap:
	lis r12, "addr_MEMFreeToDefaultHeap"@ha
	lwz r12, "addr_MEMFreeToDefaultHeap"@l (r12)
	lwz r12, 0 (r12)
	mtctr r12
	bctr

/**========================================================================
 **                                OSFatal
 *?  Halts the system and displays a message.
 *@param1 r3 "Message" address
 *========================================================================**/
OSFatal:
	GOTO_EXPORT_FUNC "OSFatal"


/**========================================================================
 * *                                INFO
 *   
 *   ! Beginning of read only data used by the code handler.
 *   
 *
 *========================================================================**/
coreinit_ascii:
	.asciz "coreinit.rpl"

OSFatal_ascii:
	.asciz "OSFatal"
OSIsAddressValid_ascii:
	.asciz "OSIsAddressValid"

memcpy_ascii:
	.asciz "memcpy"

OSBlockSet_ascii:
	.asciz "OSBlockSet"

DCFlushRange_ascii:
	.asciz "DCFlushRange"

OSEffectiveToPhysical_ascii:
	.asciz "OSEffectiveToPhysical"

OSScreenInit_ascii:
	.asciz "OSScreenInit"

OSScreenGetBufferSizeEx_ascii:
	.asciz "OSScreenGetBufferSizeEx"

OSScreenSetBufferEx_ascii:
	.asciz "OSScreenSetBufferEx"

OSScreenEnableEx_ascii:
	.asciz "OSScreenEnableEx"

OSScreenClearBufferEx_ascii:
	.asciz "OSScreenClearBufferEx"

OSScreenPutFontEx_ascii:
	.asciz "OSScreenPutFontEx"

OSScreenFlipBuffersEx_ascii:
	.asciz "OSScreenFlipBuffersEx"

vpad_ascii:
	.asciz "vpad.rpl"

VPADInit_ascii:
	.asciz "VPADInit"

VPADRead_ascii:
	.asciz "VPADRead"

padscore_ascii:
	.asciz "padscore.rpl"

KPADInit_ascii:
	.asciz "KPADInit"

KPADReadEx_ascii:
	.asciz "KPADReadEx"

WPADInit_ascii:
	.asciz "WPADInit"

MEMAllocFromDefaultHeapEx_ascii:
	.asciz "MEMAllocFromDefaultHeapEx"

MEMFreeToDefaultHeap_ascii:
	.asciz "MEMFreeToDefaultHeap"

avm_ascii:
	.asciz "avm.rpl"

AVMGetDRCScanMode_ascii:
	.asciz "AVMGetDRCScanMode"

dc_ascii:
	.asciz "dc.rpl"

DCUpdate_ascii:
	.asciz "DCUpdate"

ModuleLoadFailure:
	.string "Code Handler OSDynLoad_FindExport FAILED."

	.align 0x2

IntToFloat_magic:
	.double 4503601774854144.0
