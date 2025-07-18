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
!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_INSTALLMODE_INSTDIR "${PRODUCT_NAME}"
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_USE_PROGRAMFILES64

!include "MultiUser.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"

; MUI Settings
!define MUI_ICON "eden.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; License page
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"

; All/Current user selection page
!define MULTIUSER_PAGE_CUSTOMFUNCTION_LEAVE InstallModeLeave
!insertmacro MULTIUSER_PAGE_INSTALLMODE

; Directory page
!insertmacro MUI_PAGE_DIRECTORY

; Install option page
Page custom InstallOptionPageCreate InstallOptionPageLeave

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
Page custom CustomFinishPageCreate CustomFinishPageLeave

; Clean Uninstall page
UninstPage custom un.CleanUninstallPageCreate un.CleanUninstallPageLeave

; Uninstall page
!insertmacro MUI_UNPAGE_INSTFILES

; Uninstaller finish page
UninstPage custom un.CustomFinishPageCreate un.CustomFinishPageLeave

; Variables
Var DisplayName
Var InstallOptionPageDialog
Var DesktopShortcutCheckbox
Var DesktopShortcut
Var PortableModeCheckbox
Var PortableMode
Var CleanInstallCheckbox
Var CleanInstall
Var CustomFinishPageDialog
Var AssociateFilesCheckbox
Var AssociateFiles
Var LaunchEdenCheckbox
Var LaunchEden
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
  !insertmacro MULTIUSER_INIT
  !insertmacro MUI_LANGDLL_DISPLAY

  ; Installed version detection
  ReadRegStr $R0 HKCU "${PRODUCT_UNINST_KEY}" "DisplayVersion"
  ${If} $R0 == ""
    ReadRegStr $R0 HKLM "${PRODUCT_UNINST_KEY}" "DisplayVersion"
  ${EndIf}

  ${If} $R0 != ""
    IntCmp $R0 ${PRODUCT_VERSION} continue continue warn
    warn:
      MessageBox MB_ICONEXCLAMATION|MB_YESNO "A newer version of Eden ($R0) is already installed.$\nYou are attempting to install an older version (${PRODUCT_VERSION}).$\n$\nDo you want to continue with the downgrade?" IDYES continue
      Abort
    continue:
  ${EndIf}
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

!macro ResetCleanInstall
  StrCpy $CleanInstall 0
  ${NSD_SetState} $CleanInstallCheckbox $CleanInstall
  Abort
!macroend

!macro ResetCleanUninstall
  StrCpy $CleanUninstall 0
  ${NSD_SetState} $CleanUninstallCheckbox $CleanUninstall
  Abort
!macroend

Function InstallModeLeave
  ; Read previous install path from registry
  ReadRegStr $R0 HKCU "${PRODUCT_UNINST_KEY}" "InstallLocation"
  ${If} $R0 == ""
    ReadRegStr $R0 HKLM "${PRODUCT_UNINST_KEY}" "InstallLocation"
  ${EndIf}
  ${If} $R0 != ""
    StrCpy $INSTDIR "$R0"
  ${EndIf}
FunctionEnd
    
Function InstallOptionPageCreate
  !insertmacro MUI_HEADER_TEXT "Installation Options" "Customize your Eden installation"
  nsDialogs::Create 1018
  Pop $InstallOptionPageDialog
  ${If} $InstallOptionPageDialog == error
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

Function InstallOptionPageLeave
  ${NSD_GetState} $DesktopShortcutCheckbox $DesktopShortcut
  ${NSD_GetState} $PortableModeCheckbox $PortableMode
  ${NSD_GetState} $CleanInstallCheckbox $CleanInstall
  
  ; Detect both portable mode and appdata configs
  StrCpy $0 0 ; initial portable mode
  StrCpy $1 0 ; initial appdata exits

  ${If} ${FileExists} "$INSTDIR\user"
    StrCpy $0 1
  ${EndIf}

  SetShellVarContext current ; Set current due to eden default config location
  ${If} ${FileExists} "$APPDATA\eden"
    StrCpy $1 1
  ${EndIf}
  
  ${If} $CleanInstall == 1
    ${If} $0 == 0
      ${If} $1 == 0
        MessageBox MB_ICONINFORMATION "No previous user data was found! Clean install is not needed."
        !insertmacro ResetCleanInstall
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Default mode user data detected in AppData at:$\n$APPDATA\eden$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue
        !insertmacro ResetCleanInstall
        continue:
      ${EndIf}
    ${ElseIf} $0 == 1
      ${If} $1 == 1
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Multiple user data folders were detected:$\n$\n- Portable mode: $INSTDIR\user$\n- Default mode: $APPDATA\eden$\n$\nDo you want to delete them both?$\nThis will remove all user settings, caches, and saves." IDYES continue2
        !insertmacro ResetCleanInstall
        continue2:
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Portable mode user data detected at:$\n$INSTDIR\user$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue3
        !insertmacro ResetCleanInstall
        continue3:
      ${EndIf}
    ${EndIf}
  ${ElseIf} $PortableMode == 1
    ${If} $0 == 1
      ${If} $1 == 1
        MessageBox MB_ICONQUESTION|MB_YESNO "Portable mode selected, but multiple user data folders were detected:$\n$\n- Portable mode: $INSTDIR\user$\n- Default mode: $APPDATA\eden$\n$\nDo you want to use the AppData user data to overwrite the portable one?" IDYES use_appdata
        ; If user chose to keep portable mode user data
        RMDir /r "$APPDATA\eden"
        MessageBox MB_ICONINFORMATION "Default mode user data folders deleted. Using portable user data."
        Goto done_migration
        
        use_appdata:
          RMDir /r "$INSTDIR\user"
          CreateDirectory "$INSTDIR\user"
          CopyFiles /SILENT "$APPDATA\eden\*" "$INSTDIR\user\"
          MessageBox MB_ICONINFORMATION "Default mode user data migrated to portable mode."
        Goto done_migration
      ${Else}
        ; Only portable exists, do nothing
        MessageBox MB_ICONINFORMATION "Portable mode enabled. Existing user data will be used."
      ${EndIf}
    ${Else}
      ${If} $1 == 1
        MessageBox MB_YESNO|MB_ICONQUESTION "Portable mode selected, but default mode user data detected at:$\n$APPDATA\eden$\n$\nDo you want to migrate it to portable mode?" IDNO skip_migration
        CreateDirectory "$INSTDIR\user"
        CopyFiles /SILENT "$APPDATA\eden\*" "$INSTDIR\user\"
        RMDir /r "$APPDATA\eden"
        MessageBox MB_ICONINFORMATION "Default mode user data migrated to portable mode."
        skip_migration:
      ${Else}
        ; If none of previous user data exists, just create the user folder
        CreateDirectory "$INSTDIR\user"
        MessageBox MB_ICONINFORMATION "Portable mode enabled. A new user data folder was created."
      ${EndIf}
    ${EndIf}
  ${EndIf}
  done_migration:
FunctionEnd

Function CustomFinishPageCreate
  !insertmacro MUI_HEADER_TEXT "Installation Complete" "Eden has been installed successfully."
  nsDialogs::Create 1018
  Pop $CustomFinishPageDialog
  ${If} $CustomFinishPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Associate Eden with .nsp, .xci files"
  Pop $AssociateFilesCheckbox
  ${NSD_SetState} $AssociateFilesCheckbox $AssociateFiles

  ${NSD_CreateCheckbox} 0u 16u 100% 12u "Launch Eden after install"
  Pop $LaunchEdenCheckbox
  ${NSD_SetState} $LaunchEdenCheckbox $LaunchEden

  nsDialogs::Show
FunctionEnd

Function CustomFinishPageLeave
  ${NSD_GetState} $AssociateFilesCheckbox $AssociateFiles
  ${NSD_GetState} $LaunchEdenCheckbox $LaunchEden
  
  ${If} $LaunchEden == 1
    Exec "$INSTDIR\eden.exe"
  ${EndIf}
FunctionEnd

Function un.CleanUninstallPageCreate
  !insertmacro MUI_HEADER_TEXT "Uninstallation Options" "Customize your Eden uninstallation"
  nsDialogs::Create 1018
  Pop $UninstallerPageDialog
  ${If} $UninstallerPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Clean Uninstall (Remove all user data)"
  Pop $CleanUninstallCheckbox
  ${NSD_SetState} $CleanUninstallCheckbox 0 ; unchecked by default

  nsDialogs::Show
FunctionEnd

Function un.CleanUninstallPageLeave
  ${NSD_GetState} $CleanUninstallCheckbox $CleanUninstall

  ${If} $CleanUninstall == 1
    ; Detect both portable mode and appdata configs
    StrCpy $0 0 ; initial portable mode
    StrCpy $1 0 ; initial appdata exits

    ${If} ${FileExists} "$INSTDIR\user"
      StrCpy $0 1
    ${EndIf}

    SetShellVarContext current ; Set current due to eden default config location
    ${If} ${FileExists} "$APPDATA\eden"
      StrCpy $1 1
    ${EndIf}

    ${If} $0 == 0
      ${If} $1 == 0
        MessageBox MB_ICONINFORMATION "No user data was found! Clean uninstall is not needed."
        !insertmacro ResetCleanUninstall
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "User data detected in AppData at:$\n$APPDATA\eden$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue
        !insertmacro ResetCleanUninstall
        continue:
      ${EndIf}
    ${ElseIf} $0 == 1
      ${If} $1 == 1
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Multiple user data folders were detected:$\n$\n- Portable mode: $INSTDIR\user$\n- Default mode: $APPDATA\eden$\n$\nDo you want to delete them both?$\nThis will remove all user settings, caches, and saves." IDYES continue2
        !insertmacro ResetCleanUninstall
        continue2:
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Portable mode user data detected at:$\n$INSTDIR\user$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue3
        !insertmacro ResetCleanUninstall
        continue3:
      ${EndIf}
    ${EndIf}
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

Section "Installation"
  SectionIn RO
  !insertmacro UPDATE_DISPLAYNAME
  
  ${If} $CleanInstall == 1
    ${If} $INSTDIR != ""
      ${If} ${FileExists} "$INSTDIR\eden.exe"
        RMDir /r "$INSTDIR"
      ${EndIf}

      ; Attempt to clean portable mode data if exists
      ${If} ${FileExists} "$INSTDIR\user"
        RMDir /r "$INSTDIR\user"
      ${EndIf}
        
      ; Attempt to clean AppData config if exists
      SetShellVarContext current
      ${If} ${FileExists} "$APPDATA\eden"
        DeleteRegKey HKCU "Software\eden"
        RMDir /r "$APPDATA\eden"
      ${EndIf}
        
      ; Remove old start menu shortcuts
      Delete "$SMPROGRAMS\${PRODUCT_NAME}\$DisplayName.lnk"
      Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall $DisplayName.lnk"
      RMDir  "$SMPROGRAMS\${PRODUCT_NAME}"

      ; Remove old desktop shortcut
      Delete "$DESKTOP\$DisplayName.lnk" 
    ${EndIf}
  ${EndIf}

  SetOutPath "$INSTDIR"
  File /r "${BINARY_SOURCE_DIR}\*"

  ; Create start menu and desktop shortcuts
  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\$DisplayName.lnk" "$INSTDIR\eden.exe"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall $DisplayName.lnk" "$INSTDIR\uninst.exe" "/$MultiUser.InstallMode"
  ${If} $DesktopShortcut == 1
    CreateShortCut "$DESKTOP\$DisplayName.lnk" "$INSTDIR\eden.exe"
  ${EndIf}

  SetOutPath "$TEMP"
  SetAutoClose false
SectionEnd

Section -RegisterUninstallerMetadata
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr SHCTX "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\eden.exe"
  
  ${If} $AssociateFiles == 1
    ${If} $MultiUser.InstallMode == "AllUsers"
      ; NSP association
      WriteRegStr HKCR ".nsp" "" "eden.nsp"
      WriteRegStr HKCR "eden.nsp" "" "Eden NSP File"
      WriteRegStr HKCR "eden.nsp\DefaultIcon" "" "$INSTDIR\eden.exe,0"
      WriteRegStr HKCR "eden.nsp\shell\open\command" "" '"$INSTDIR\eden.exe" "%1"'

      ; XCI association
      WriteRegStr HKCR ".xci" "" "eden.xci"
      WriteRegStr HKCR "eden.xci" "" "Eden XCI File"
      WriteRegStr HKCR "eden.xci\DefaultIcon" "" "$INSTDIR\eden.exe,0"
      WriteRegStr HKCR "eden.xci\shell\open\command" "" '"$INSTDIR\eden.exe" "%1"'

    ${Else}
      ; NSP association
      WriteRegStr HKCU "Software\Classes\.nsp" "" "eden.nsp"
      WriteRegStr HKCU "Software\Classes\eden.nsp" "" "Eden NSP File"
      WriteRegStr HKCU "Software\Classes\eden.nsp\DefaultIcon" "" "$INSTDIR\eden.exe,0"
      WriteRegStr HKCU "Software\Classes\eden.nsp\shell\open\command" "" '"$INSTDIR\eden.exe" "%1"'

      ; XCI association
      WriteRegStr HKCU "Software\Classes\.xci" "" "eden.xci"
      WriteRegStr HKCU "Software\Classes\eden.xci" "" "Eden XCI File"
      WriteRegStr HKCU "Software\Classes\eden.xci\DefaultIcon" "" "$INSTDIR\eden.exe,0"
      WriteRegStr HKCU "Software\Classes\eden.xci\shell\open\command" "" '"$INSTDIR\eden.exe" "%1"'
    ${EndIf}
  ${EndIf}


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

  ; Remove shortcuts
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall $DisplayName.lnk"
  Delete "$DESKTOP\$DisplayName.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\$DisplayName.lnk"
  RMDir "$SMPROGRAMS\${PRODUCT_NAME}"
    
  ${If} $CleanUninstall == 1
    ; Attempt to clean portable mode data if exists
    ${If} ${FileExists} "$INSTDIR\user"
      RMDir /r "$INSTDIR\user"
    ${EndIf}
        
    ; Attempt to clean AppData config if exists
    SetShellVarContext current
    ${If} ${FileExists} "$APPDATA\eden"
      DeleteRegKey HKCU "Software\eden"
      RMDir /r "$APPDATA\eden"
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

  ; Delete eden's file associations
  ${If} $MultiUser.InstallMode == "AllUsers"
    DeleteRegKey HKCR ".nsp"
    DeleteRegKey HKCR ".xci"
    DeleteRegKey HKCR "eden.nsp"
    DeleteRegKey HKCR "eden.xci"
  ${Else}
    DeleteRegKey HKCU "Software\Classes\.nsp"
    DeleteRegKey HKCU "Software\Classes\.xci"
    DeleteRegKey HKCU "Software\Classes\eden.nsp"
    DeleteRegKey HKCU "Software\Classes\eden.xci"
  ${EndIf}
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.nsp"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.xci"

  
  DeleteRegKey HKCU "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKCU "${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"

  SetAutoClose false
SectionEnd
