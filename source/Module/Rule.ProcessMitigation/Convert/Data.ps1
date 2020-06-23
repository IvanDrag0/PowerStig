# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

data regularExpression
{
    ConvertFrom-StringData -StringData @'
        MitigationTarget = (?<=Get-ProcessMitigation -)(System)|(?<=Get-ProcessMitigation -Name\\s)([^"]+)
        MitigationTargetName = .*.EXE|.*.exe|System
        MitigationType   = Aslr|BinarySignature|Cfg|Child Process|DEP|DynamicCode|ExtensionPoint|FontDisable|Heap|ImageLoad|Payload|SEHOP|StrictHandle|SystemCall
        MitigationName   = HighEntropy|OverrideHighEntropy|BottomUp|OverrideEnableExportAddressFilterPlus|OverrideForceRelocateImages|RequireInfo|ForceRelocateImages|OverrideBottomUp|AllowStoreSignedBinaries|AuditMicrosoftSignedOnly|OverrideMicrosoftSignedOnly|AuditEnforceModuleDependencySigning|AuditStoreSigned|OverrideDependencySigning|MicrosoftSignedOnly|EnforceModuleDependencySigning|StrictControlFlowGuard|OverrideCFG|OverrideStrictCFG|Enable|SuppressExports|OverrideChildProcess|DisallowChildProcessCreation|Audit|EmulateAtlThunks|Override DEP|OverrideDynamicCode|BlockDynamicCode|AllowThreadsToOptOut|DisableExtensionPoints|OverrideExtensionPoint|OverrideFontDisable|DisableNonSystemFonts|TerminateOnError|OverrideHeap|OverrideBlockLowLabel|OverridePreferSystem32|ImageLoad OverrideBlockRemoteImages|AuditPreferSystem32|PreferSystem32|AuditLowLabelImageLoads|BlockLowLabelImageLoads|AuditRemoteImageLoads|BlockRemoteImageLoads|EAFModules|AuditEnableExportAddressFilterPlus|EnableRopStackPivot|EnableExportAddressFilter|OverrideEnableRopStackPivot|AuditEnableRopCallerCheck|OverrideEnableRopCallerCheck|AuditEnableRopStackPivot|OverrideEnableImportAddressFilter|OverrideEnableExportAddressFilter|EnableExportAddressFilterPlus|AuditEnableRopSimExec|AuditEnableImportAddressFilter|OverrideEnableRopSimExec|EnableRopCallerCheck|AuditEnableExportAddressFilter|EnableRopSimExec|EnableImportAddressFilter|TelemetryOnly|OverrideSEHOP|OverrideStrictHandle|DisableWin32kSystemCalls|OverrideSystemCall
        MitigationValue = True|False|ON
'@
}



