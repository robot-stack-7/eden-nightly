; Copyright Dolphin Emulator Project / Azahar Emulator Project / eden Emulator Project
; Licensed under GPLv3

; Require /DPRODUCT_VERSION=<release-name> to makensis.
!ifndef PRODUCT_VERSION
  !error "PRODUCT_VERSION must be defined"
!endif

; Require /DPRODUCT_VARIANT=<release-name> to makensis.
!ifndef PRODUCT_VARIANT
  !error "PRODUCT_VARIANT must be defined"
!endif

!define PRODUCT_NAME "Eden Nightly"
!define PRODUCT_PUBLISHER "Eden Emulator Developers"
!define PRODUCT_WEB_SITE "https://eden-emu.dev/"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_NAME}.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

!define BINARY_SOURCE_DIR "..\eden\build\bin"

Name "${PRODUCT_NAME}"
OutFile "Eden-${PRODUCT_VERSION}-Windows-${PRODUCT_VARIANT}-Installer.exe"
BrandingText "${PRODUCT_NAME} Installer v${PRODUCT_VERSION} (${PRODUCT_VARIANT})"
SetCompressor /SOLID lzma
ShowInstDetails show
ShowUnInstDetails show

; Setup MultiUser support:
; If launched without ability to elevate, user will not see any extra options.
; If user has ability to elevate, they can choose to install system-wide, with default to CurrentUser.
!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_INSTALLMODE_INSTDIR "${PRODUCT_NAME}"
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_USE_PROGRAMFILES64
!include "MultiUser.nsh"

!include "MUI2.nsh"
; Custom page plugin
!include "nsDialogs.nsh"

; MUI Settings
!define MUI_ICON "eden.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; License page
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"

; All/Current user selection page
!insertmacro MULTIUSER_PAGE_INSTALLMODE

; Desktop Shortcut page
Page custom desktopShortcutPageCreate desktopShortcutPageLeave

; Directory page
!include "FileFunc.nsh"
!define MUI_PAGE_CUSTOMFUNCTION_PRE pre.Directory
!insertmacro MUI_PAGE_DIRECTORY
  
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
!insertmacro MUI_PAGE_FINISH

; Clean Uninstall page
UninstPage custom un.CleanUninstallPageCreate un.CleanUninstallPageLeave

; Uninstall page
!insertmacro MUI_UNPAGE_INSTFILES

; Uninstaller finish page
UninstPage custom un.CustomFinishPageCreate un.CustomFinishPageLeave

; Variables
Var DisplayName
Var DesktopShortcutPageDialog
Var DesktopShortcutCheckbox
Var DesktopShortcut
Var PortableModeCheckbox
Var PortableMode
Var CleanInstallCheckbox
Var CleanInstall
Var UninstallerPageDialog
Var CleanUninstallCheckbox
Var CleanUninstall
Var UnFinishPageDialog
Var OpenLatestCheckbox
Var OpenLatest

; Language files
!insertmacro MUI_LANGUAGE "Arabic"
!insertmacro MUI_LANGUAGE "Catalan"
!insertmacro MUI_LANGUAGE "Czech"
!insertmacro MUI_LANGUAGE "Danish"
!insertmacro MUI_LANGUAGE "Dutch"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Finnish"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Greek"
!insertmacro MUI_LANGUAGE "Hungarian"
!insertmacro MUI_LANGUAGE "Indonesian"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Japanese"
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "Norwegian"
!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "Portuguese"
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "SpanishInternational"
!insertmacro MUI_LANGUAGE "Swedish"
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGE "Ukrainian"
!insertmacro MUI_LANGUAGE "Vietnamese"

; MUI end ------

Function .onInit
  StrCpy $DesktopShortcut 0 ; default to unchecked
  !insertmacro MULTIUSER_INIT
  
  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

!macro UPDATE_DISPLAYNAME
  ${If} $MultiUser.InstallMode == "CurrentUser"
    StrCpy $DisplayName "$(^Name) (User)"
  ${Else}
    StrCpy $DisplayName "$(^Name)"
  ${EndIf}
!macroend

Function desktopShortcutPageCreate
  !insertmacro MUI_HEADER_TEXT "Installation Options" "Customize your Eden installation"
  nsDialogs::Create 1018
  Pop $DesktopShortcutPageDialog
  ${If} $DesktopShortcutPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Create a desktop shortcut"
  Pop $DesktopShortcutCheckbox
  ${NSD_SetState} $DesktopShortcutCheckbox $DesktopShortcut

  ${NSD_CreateCheckbox} 0u 16u 100% 12u "Enable portable mode (Store Eden config folders in install folder)"
  Pop $PortableModeCheckbox
  ${NSD_SetState} $PortableModeCheckbox $PortableMode

  ${NSD_CreateCheckbox} 0u 32u 100% 12u "Clean install (Remove previous installation files)"
  Pop $CleanInstallCheckbox
  ${NSD_SetState} $CleanInstallCheckbox $CleanInstall

  nsDialogs::Show
FunctionEnd

Function desktopShortcutPageLeave
  ${NSD_GetState} $DesktopShortcutCheckbox $DesktopShortcut
  ${NSD_GetState} $PortableModeCheckbox $PortableMode
  ${NSD_GetState} $CleanInstallCheckbox $CleanInstall
  
  ${If} $CleanInstall == 1
    MessageBox MB_ICONEXCLAMATION|MB_YESNO "Clean Install Warning:$\n$\nThis will permanently delete all user configuration, cache and save files.$\n$\nAre you sure you want to continue?" IDYES continue
    StrCpy $CleanInstall 0
    ${NSD_SetState} $CleanInstallCheckbox $CleanInstall
    Abort
    continue:
  ${EndIf}
FunctionEnd

Function pre.Directory
  ; Set correct shell context first, maybe redundant, but I need to be sure about it
  ${If} $MultiUser.InstallMode == "CurrentUser"
    SetShellVarContext current
  ${Else}
    SetShellVarContext all
  ${EndIf}

  ; Now try to read previous install path from registry
  ReadRegStr $R0 SHCTX "${PRODUCT_UNINST_KEY}" "InstallLocation"
  ${If} $R0 != ""
    StrCpy $INSTDIR "$R0"
    DetailPrint "Restoring install location: $R0"
  ${Else}
    DetailPrint "No previous install location found, using default: $INSTDIR"
  ${EndIf}
FunctionEnd

Function un.CleanUninstallPageCreate
  !insertmacro MUI_HEADER_TEXT "Uninstallation Options" "Customize your Eden uninstallation"
  nsDialogs::Create 1018
  Pop $UninstallerPageDialog
  ${If} $UninstallerPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Remove all user data"
  Pop $CleanUninstallCheckbox
  ${NSD_SetState} $CleanUninstallCheckbox 0 ; unchecked by default

  nsDialogs::Show
FunctionEnd

Function un.CleanUninstallPageLeave
  ${NSD_GetState} $CleanUninstallCheckbox $CleanUninstall
  ${If} $CleanUninstall == 1
    MessageBox MB_ICONEXCLAMATION|MB_YESNO "Clean Uninstall Warning:$\n$\nThis will permanently delete all user configuration, cache and save files.$\n$\nAre you sure you want to continue?" IDYES continue
    StrCpy $CleanUninstall 0
    ${NSD_SetState} $CleanUninstallCheckbox $CleanUninstall
    Abort
    continue:
  ${EndIf}
FunctionEnd

Function un.CustomFinishPageCreate
  !insertmacro MUI_HEADER_TEXT "Uninstallation Complete" "Eden has been removed from your computer."
  nsDialogs::Create 1018
  Pop $UnFinishPageDialog
  ${If} $UnFinishPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Get the latest Eden nightly"
  Pop $OpenLatestCheckbox
  ${NSD_SetState} $OpenLatestCheckbox $OpenLatest

  nsDialogs::Show
FunctionEnd

Function un.CustomFinishPageLeave
  ${NSD_GetState} $OpenLatestCheckbox $OpenLatest
  ${If} $OpenLatest == 1
    ExecShell "open" "https://github.com/pflyly/eden-nightly/releases/latest"
  ${EndIf}
FunctionEnd

Section "Base"

  SectionIn RO

  ${If} $CleanInstall == 1
    ${If} $INSTDIR != ""
      ${If} ${FileExists} "$INSTDIR\eden.exe"
        RMDir /r "$INSTDIR"
      ${EndIf}

      ; If NOT in portable mode, also clean eden config dir in AppData\Roaming
      ${IfNot} $PortableMode == 1
        DeleteRegKey HKCU "Software\eden"
        RMDir /r "$APPDATA\eden"
      ${EndIf}
    ${EndIf}
  ${EndIf}

  SetOutPath "$INSTDIR"

  ; The binplaced build output will be included verbatim.
  File /r "${BINARY_SOURCE_DIR}\*"

  !insertmacro UPDATE_DISPLAYNAME
  
  ; Ensure shell var context matches the install mode
  ${If} $MultiUser.InstallMode == "CurrentUser"
    SetShellVarContext current
  ${Else}
    SetShellVarContext all
  ${EndIf}

  ${If} $PortableMode == 1
    CreateDirectory "$INSTDIR\user"
  ${EndIf}

  ; Create start menu and desktop shortcuts
  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\$DisplayName.lnk" "$INSTDIR\eden.exe"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall $DisplayName.lnk" "$INSTDIR\uninst.exe" "/$MultiUser.InstallMode"
  ${If} $DesktopShortcut == 1
    CreateShortCut "$DESKTOP\$DisplayName.lnk" "$INSTDIR\eden.exe"
  ${EndIf}

  ; ??
  SetOutPath "$TEMP"
SectionEnd

!include "FileFunc.nsh"

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr SHCTX "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\eden.exe"

  ; Write metadata for add/remove programs applet
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayName" "$DisplayName"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe /$MultiUser.InstallMode"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\eden.exe"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "InstallLocation" "$INSTDIR"
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD SHCTX "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "Comments" "Nintendo Switch emulator"
SectionEnd

Section Uninstall
  !insertmacro UPDATE_DISPLAYNAME

  ; Ensure we use the correct shell var context
  ${If} $MultiUser.InstallMode == "CurrentUser"
    SetShellVarContext current
  ${Else}
    SetShellVarContext all
  ${EndIf}

  ; Remove shortcuts
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall $DisplayName.lnk"
  Delete "$DESKTOP\$DisplayName.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\$DisplayName.lnk"
  RMDir "$SMPROGRAMS\${PRODUCT_NAME}"
    
  ; Clean user data first on clean uninstall mode
  ${If} $CleanUninstall == 1
    ${If} ${FileExists} "$INSTDIR\user"
      ; Portable mode
      RMDir /r "$INSTDIR\user"
    ${Else}
      ; Normal mode
      RMDir /r "$APPDATA\eden"
      DeleteRegKey HKCU "Software\eden"
    ${EndIf}
  ${EndIf}
    
  ; Remove installed files
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\eden.exe"
  Delete "$INSTDIR\uninst.exe"
  RMDir /r "$INSTDIR\generic"
  RMDir /r "$INSTDIR\iconengines"
  RMDir /r "$INSTDIR\imageformats"
  RMDir /r "$INSTDIR\networkinformation"
  RMDir /r "$INSTDIR\platforms"
  RMDir /r "$INSTDIR\styles"
  RMDir /r "$INSTDIR\tls"
  RMDir /r "$INSTDIR\translations"
  RMDir "$INSTDIR"
  
  DeleteRegKey SHCTX "${PRODUCT_UNINST_KEY}"
  DeleteRegKey SHCTX "${PRODUCT_DIR_REGKEY}"

  SetAutoClose false
SectionEnd
