; Publican installer

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "EnvVarUpdate.nsh"
  
;--------------------------------
;General

  ;Name and file
  Name "Publican"
  OutFile "Publican-Beta-Installer.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\Publican"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKLM  "Software\Publican" ""

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

;--------------------------------
;Interface Configuration

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
  !define MUI_HEADERIMAGE_BITMAP "publican.bmp"
  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "..\COPYING"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "Main" SecMain

  SetOutPath "$INSTDIR"
  
  file /r ..\blib\datadir\*
  file publican.exe
  
  ;Store installation folder
  WriteRegStr HKLM  "Software\Publican" "" $INSTDIR
  ; TODO confirm this works on Vista
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Hide first run IO error
  nsExec::Exec "$INSTDIR\publican.exe"
SectionEnd

SectionGroup "DocBook" SecDocBook
Section "DTD" SecDocBookDTD

  SetOutPath "$INSTDIR\DocBook_DTD"
  
  file /r ..\..\DTD\*
  WriteRegStr HKLM  "Software\Publican" "dtd_path" "$INSTDIR\DocBook_DTD"

SectionEnd
Section "XSL" SecDocBookXSL

  SetOutPath "$INSTDIR\DocBook_XSL"
  
  file /r ..\..\docbook-xsl-1.74.3\*
  WriteRegStr HKLM  "Software\Publican" "xsl_path" "$INSTDIR\DocBook_XSL"
SectionEnd
SectionGroupEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecMain ${LANG_ENGLISH} "The Publican program."
  LangString DESC_SecDocBook ${LANG_ENGLISH} "Speed things up by including local DTD and XSL"
  LangString DESC_SecDocBookDTD ${LANG_ENGLISH} "The DocBook DTD."
  LangString DESC_SecDocBookXSL ${LANG_ENGLISH} "The DocBook XSL."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDocBook} $(DESC_SecDocBook)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDocBookDTD} $(DESC_SecDocBookDTD)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDocBookXSL} $(DESC_SecDocBookXSL)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Uninstaller Section

Section "Uninstall"

  Delete "$INSTDIR\Uninstall.exe"

  RMDir /r "$INSTDIR"

  DeleteRegKey HKLM  "Software\Publican"
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" $INSTDIR
  
SectionEnd