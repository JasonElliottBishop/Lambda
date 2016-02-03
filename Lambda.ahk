;##################################################################################
;Lambda.ahk Version 1.3.3
;Author: Jason Bishop
;Created with AutoHotKey_L http://www.autohotkey.com/
;##################################################################################
Var_Version = 1.3.2
;##################################################################################
;                               __START AUTOEXEC SECTION__
;##################################################################################
; -----------------------------------------------------
; Directives
; -----------------------------------------------------
#SingleInstance force

; -----------------------------------------------------
; TRAY MENU
; -----------------------------------------------------
Menu, Tray, noStandard
Menu, Tray, Icon, Icons\Lambda.ico,, 1
Menu, BackupSub, Add, Backup: (On/Off), Sub_BackupToggle
Menu, BackupSub, Add, ; Separator
Menu, BackupSub, Add, Edit Backup Locations, Sub_EditLoc 
Menu, BackupSub, Add, Reload Backup Locations, Sub_PExtFile
Menu, BackupSub, Add, ; Separator
Menu, BackupSub, Add, Start Incremental Backup, Sub_IncBackup
Menu, BackupSub, Add, Start Full Backup, Sub_FullBackup
Menu, BackupSub, Add, ; Separator
Menu, BackupSub, Add, Show Log, Sub_ShowBackupLog
Menu, Tray, Add, Backup, :BackupSub
Menu, Tray, Add, Keep Alive: (On/Off), Sub_KeepAliveToggle
Menu, Tray, Add, RegEx SandBox, Sub_SandBox
Menu, Tray, Add, Window Spy, Sub_Spy
Menu, Tray, Add, ; Separator
Menu, Tray, Add, Edit Hotkeys, Sub_EditHotKeys
Menu, Tray, Add, Edit AutoReplace, Sub_EditAutoRep
Menu, Tray, Add, ; Separator
Menu, Tray, Add, Settings, Sub_EditSettings
Menu, Tray, Add, Reload Script, Sub_Reload
Menu, Tray, Add, About, Sub_About
Menu, Tray, Add, Exit, Sub_Exit
Menu, Tray, Default, Reload Script

; -----------------------------------------------------
; Lambda External Files
; -----------------------------------------------------
Var_Settings = Config\Settings.ini      ; Lambda main settings file
Var_ExtFile = Config\Backup.cfg         ; Backup configuration file
Var_BackupLog = Logs\Backup.log         ; Backup log file
Var_HotKeys = Config\Hotkey.cfg         ; Hotkey config file
Var_AutoRep = Config\AutoReplace.cfg    ; AutoReplace config file

; -----------------------------------------------------
; Get Backup Settings from Settings.ini
; -----------------------------------------------------
IniRead, Var_BUActive, %Var_Settings%, Backup, Active
IniRead, Var_BackupInterval, %Var_Settings%, Backup, Interval
IniRead, Var_MaxLogEntries, %Var_Settings%, Backup, MaxLogEntries
IniRead, Var_MaxDays, %Var_Settings%, Backup, MaxDays

; -----------------------------------------------------
; Get KeepAlive Settings from Settings.ini
; -----------------------------------------------------
IniRead, Var_KAActive, %Var_Settings%, KeepAlive, Active
IniRead, Var_KAInterval, %Var_Settings%, KeepAlive, Interval
IniRead, Var_KAIdleMax, %Var_Settings%, KeepAlive, MaxIdle

; -----------------------------------------------------
; Minute to Millisecond Conversions
; -----------------------------------------------------
Var_KAIdleMax := Var_KAIdleMax*60000
Var_KAInterval := Var_KAInterval*60000
Var_BackupInterval := Var_BackupInterval*60000

; -----------------------------------------------------
; Execute Subroutines
; -----------------------------------------------------
Gosub, Sub_Startup

; -----------------------------------------------------
; Includes
; -----------------------------------------------------
#Include Include\Notify.ahk
#Include Config\Hotkey.cfg
#Include Config\AutoReplace.cfg

Return

;##################################################################################
;                              __END AUTOEXEC SECTION__
;##################################################################################

; ----------------------------------------------------- 
; Optionally Cancel Backup while running 
; ----------------------------------------------------- 
Sub_Cancel:  
if Var_Running = 1 
{ 
    Var_StopProcess = 1 
} 
Return

; ----------------------------------------------------- 
; Timed Backup
; ----------------------------------------------------- 
Sub_Backup:
if Var_Pbar = 1
{
    NotifyID := Notify("Backup Progress","", 1, "PG=10 PC=black GC=555555 TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500")
}
; ----------------------------------------------------- 
; Start Time
; ----------------------------------------------------- 
Var_Location = %Var_Location%Backup Started: %A_DDDD%, %A_MMMM%%A_Space%%A_DD%, %A_Hour%:%A_Min%:%A_Sec% 
Var_Running = 1
; ----------------------------------------------------- 
; Count Backup Items
; -----------------------------------------------------
Var_Titems = 0 
Var_Temp1 = 
Loop, Parse, Var_BackupInfo, ? 
{ 
    Var_Titems ++ 
    if A_LoopField = 
    { 
        Var_Titems -- 
        if A_Index = 1 
        { 
            StringTrimLeft, Var_BackupInfo, Var_BackupInfo, 1 
        } 
    } 
    else 
    { 
        if Var_Titems = 1 
        { 
            Var_Temp1 = %A_LoopField% 
        } 
        else 
        { 
            Var_Temp1 = %Var_Temp1%?%A_LoopField% 
        }
    } 
} 
Var_BackupInfo = %Var_Temp1%  
Var_Temp1 = 

; ----------------------------------------------------- 
;  Split backup paths from main string 
; -----------------------------------------------------
Loop, Parse, Var_BackupInfo, ? 
{ 
    Var_ItemNum = %A_Index% 
    ; -----------------------------------------------------  
    ; Assign paths/option(s) to variables 
    ; ----------------------------------------------------- 
    Var_prep = 
    Var_appp = 
    Loop, Parse, A_LoopField, | 
    { 
        if A_Index = 1 
        { 
            Var_CopySourcePattern = %A_LoopField% 
            ; ----------------------------------------------------- 
            ; Determine path of source 
            ; ----------------------------------------------------- 
            Var_RelPath =  
            Loop, %A_LoopField%
            {
                Var_RelPath = %A_LoopFileDir%
            }    
            if Var_RelPath = 
            {
                SplitPath, A_LoopField,, Var_OutDir,,, Var_OutDrive
                StringReplace, Var_OutDir, Var_OutDir, %Var_OutDrive%,
                Var_RelPath = %Var_OutDrive%%Var_OutDir%
            }
        } 
        else if A_Index = 2 
        { 
            Var_CopyDest = %A_LoopField% 
            StringRight, Var_Temp1, Var_CopyDest, 1 
            if Var_Temp1 = \
            {
                StringTrimRight, Var_CopyDest, Var_CopyDest, 1
            }
        } 
        else if A_Index = 3 
        { 
            Var_CopySubFlag = %A_LoopField% 
        } 
        else if A_Index = 4
        { 
            Var_CpEmpty = %A_LoopField% 
        }
        else if A_index = 5
        {
            Var_prep = %A_LoopField%
        }
        else if A_index = 6
        {
            Var_appp = %A_LoopField%
        }
    }
    ; 
    ; ----------------------------------------------------- 
    ; locate files for backup 
    ; ----------------------------------------------------- 
    Loop, %Var_CopySourcePattern%, 1, %Var_CopySubFlag% 
    { 
        if Var_StopProcess = 1 
        { 
            Var_Running = 0 
            Gosub, Sub_BCancelled 
            Var_StopProcess = 0 
            Return 
        }
        If (Instr(A_LoopFileFullPath, Var_CopyDest) = 1)
        {
            Continue
        }    
        Var_LRelPath = 
        ; ----------------------------------------------------- 
        ; Get Relative Path 
        ; ----------------------------------------------------- 
        StringReplace, A_LoopRelativeFileName, A_LoopFileFullPath, %Var_RelPath%\,  ;
        ; -----------------------------------------------------
        ; determine if file needs to be backed up 
        ; ----------------------------------------------------- 
        Var_copy_it = n
        A_LoopRelativeFileNamePA = 
        If (!(Var_appp = "") OR !(Var_prep = "")) 
        {
            A_LoopRelativeFileNamePA = %A_LoopRelativeFileName%
            Var_alrfp = %Var_CopyDest%\%A_LoopRelativeFileName%
            SplitPath, Var_CopyDest,,dirt
            SplitPath, Var_alrfp, Var_alrfn, Var_alrdir, Var_alrext, Var_alrname
            StringTrimLeft, Var_alrdir, Var_alrdir, (StrLen(dirt))
            If (SubStr(Var_alrdir, 1, 1) = "\")
            {
                StringTrimLeft, Var_alrdir, Var_alrdir, 1
            }    
            StringTrimLeft, Var_alrfp, Var_alrfp, (StrLen(Var_CopyDest) + 1)
            If (SubStr(Var_alrfp, 1, 1) = "\")
            {
                StringTrimLeft, Var_alrfp, Var_alrfp, 1
            }    
            StringTrimRight, Var_alrfp, Var_alrfp, (StrLen(Var_alrname . Var_alrext) + 1)
            Var_BaseFileName = %Var_alrname%
            If !(Var_prep = "")
            {
                If (Var_prep = "A_Now")
                {
                    Var_prep = %A_Now%
                }
            Var_alrname = %Var_prep%_%Var_alrname%
            }
            If !(Var_appp = "")
            {
                If (Var_appp = "A_Now")
                {
                    Var_appp = %A_Now% 
                }
            Var_alrname = %Var_alrname%_%Var_appp%
            }
        A_LoopRelativeFileName = %Var_alrfp%%Var_alrname%.%Var_alrext%
        }
        IfNotExist, %Var_CopyDest%\%A_LoopRelativeFileName%  ; Always copy if target file doesn't yet exist.
        {
            Var_copy_it = y
        }    
        else 
        { 
            FileGetTime, time, %Var_CopyDest%\%A_LoopRelativeFileName% 
            EnvSub, time, %A_LoopFileTimeModified%, seconds  ; Subtract the source file's time from the destination's. 
            if time < 0  ; Source file is newer than destination file.
            {
                Var_copy_it = y
            }    
        } 
        if Var_doforce = 1
        {
            Var_copy_it = y
        }    
        ; ----------------------------------------------------- 
        ; backup file(s), (and files in sub directories if selected) 
        ; ----------------------------------------------------- 
        If !(A_LoopRelativeFileNamePA = "") 
        {
            A_LRPT = %A_LoopRelativeFileName%
            A_LoopRelativeFileName = %A_LoopRelativeFileNamePA% 
        }
        if Var_copy_it = y 
        {
            IfExist, %Var_CopyDest%
            {
                ; -----------------------------------------------------  
                ; Create Directory if necessary 
                ; ----------------------------------------------------- 
                Var_LRelPath = 
                Var_Temp1 = 
                FileGetAttrib, Var_LCurAttrib, %A_LoopFileFullPath% 
                IfInString, Var_LCurAttrib, D 
                { 
                    Var_LRelPath = %Var_CopyDest%\%A_LoopRelativeFileName% 
                    Var_Dir1 = 1 
                } 
                else
                {
                    Loop, %A_LoopFileFullPath% 
                    {
                        StringReplace, Var_LRelPath, A_LoopRelativeFileName, %A_LoopFileName%, 
                        Var_LRelPath = %Var_CopyDest%\%Var_LRelPath% 
                        Var_Dir1 = 0 
                    }
                }           
                StringRight, Var_Temp1, Var_LRelPath, 1 
                if Var_Temp1 = \
                {
                    StringTrimRight, Var_LRelPath, Var_LRelPath, 1
                }    
                IfNotExist, %Var_LRelPath% 
                { 
                    If Var_Dir1 = 0 
                    { 
                        Gosub, Sub_CheckNCreate 
                    } 
                    else 
                    { 
                        if Var_CopySubFlag = 1
                        {
                            if Var_CpEmpty = 1
                            {
                                Gosub, Sub_CheckNCreate
                            }
                        } 
                    }
                }    
                ; ----------------------------------------------------- 
                ; copy file 
                ; ----------------------------------------------------- 
                if Var_Dir1 = 0 
                { 
                    If !(A_LoopRelativeFileNamePA = "")
                    {
                        ; ----------------------------------------------------- 
                        ; Delete Prep or Amend files older than Var_MaxDays
                        ; ----------------------------------------------------- 
                        A_LoopRelativeFileName = %A_LRPT%
                        Loop %Var_CopyDest%\*%Var_BaseFileName%*
                        {
                            Var_TimeToDel = %A_Now%
                            EnvSub, Var_TimeToDel, %A_LoopFileTimeCreated%, D
                            If (Var_TimeToDel >= Var_MaxDays)
                            {
                                FileDelete, %A_LoopFileFullPath%
                            }    
                        }
                    }    
                    FileCopy, %A_LoopFileFullPath%, %Var_CopyDest%\%A_LoopRelativeFileName%, 1   ; Copy with overwrite=yes 
                    if ErrorLevel != 0 
                    { 
                        Var_Location = %Var_Location%`r`n Could not copy "%A_LoopFileFullPath%" to "%Var_CopyDest%\%A_LoopRelativeFileName%". 
                    } 
                    else 
                    { 
                        Var_Location = %Var_Location%`r`n Backup Ok - "%A_LoopFileFullPath%" to "%Var_CopyDest%\%A_LoopRelativeFileName%"
                    }
                    ; ----------------------------------------------------- 
                    ; Update Progress Bar 
                    ; ----------------------------------------------------- 
                    if Var_Pbar = 1
                    {
                        ProCount += 1
                        Notify("","",ProCount,"Update=" . NotifyID) 
                    }
                }
            }
        }    
    } 
} 
; ----------------------------------------------------- 
; Write log file 
; ----------------------------------------------------- 
Progress, Off 
Var_Running = 0 
if Var_BackupLog != 
{ 
    Var_Location3 = 
    Var_Temp3 = ****************************************************************? 
    Var_Location = %Var_Location%`r`nBackup Completed: %A_DDDD%, %A_MMMM%%A_Space%%A_DD%, %A_Hour%:%A_Min%:%A_Sec% 
    Var_Location = %Var_Location%`r`n%Var_Temp3% 
    FileRead, Var_Location2, %Var_BackupLog% 
    Loop, Parse, Var_Location2, ? 
    { 
        if A_Index = 1 
        { 
            Var_Location3 = `r`n%A_LoopField%? 
        } 
        else if A_Index < %Var_MaxLogEntries% 
        { 
            Var_Location3 = %Var_Location3%%A_LoopField%? 
        } 
    } 
    StringTrimRight, Var_Location3, Var_Location3, 3 
    Var_Location2 = %Var_Location3% 
    Var_Location3 = 
    Var_Location = %Var_Location%`r`n%Var_Location2% 
    FileDelete, %Var_BackupLog% 
    FileAppend, %Var_Location%, %Var_BackupLog% 
    Var_Location = 
    Var_Location2 = 
    if Var_Complete = 1 
    { 
        Notify("Backup Completed","Click here to view log.",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\check.ico AC=Sub_ShowBackupLog")
    } 
}
Return 

; ----------------------------------------------------- 
; Backup Cancelled - Write log file
; ----------------------------------------------------- 
Sub_BCancelled: 
Progress, Off 
if Var_BackupLog != 
{ 
    Var_Location3 = 
    Temp3 = ****************************************************************? 
    Var_Location = %Var_Location%`r`nBackup Cancelled: %A_DDDD%, %A_MMMM%%A_Space%%A_DD%, %A_Hour%:%A_Min%:%A_Sec% 
    Var_Location = %Var_Location%`r`n%Var_Temp3% 
    FileRead, Var_Location2, %Var_BackupLog% 
    Loop, Parse, Var_Location2, ? 
    { 
        if A_Index = 1 
        { 
            Var_Location3 = `r`n%A_LoopField%? 
        } 
        else if A_Index < %Var_MaxLogEntries% 
        { 
            Var_Location3 = %Var_Location3%%A_LoopField%? 
        } 
    } 
    StringTrimRight, Var_Location3, Var_Location3, 3 
    Var_Location2 = %Var_Location3% 
    Var_Location3 = 
    Var_Location = %Var_Location%`r`n%Var_Location2% ; linefeeds removed 
    FileDelete, %Var_BackupLog% 
    FileAppend, %Var_Location%, %Var_BackupLog% 
    Var_Location = 
    Var_Location2 = 
    if Var_Complete = 1 
    { 
        Notify("Backup Cancelled","Click here to view log.",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\cancel.ico AC=Sub_ShowBackupLog")
    } 
}
Return 

; ----------------------------------------------------- 
; Create Sub directories as necessary 
; ----------------------------------------------------- 
Sub_CheckNCreate: 
Var_CpBase = 
Loop, Parse, Var_LRelPath,\ 
{ 
    if A_Index = 1 
    { 
        if A_LoopField =
        {
            Break
        }    
        Var_CpBase = %A_LoopField% 
    } 
    else 
    { 
        Var_CpBase = %Var_CpBase%\%A_LoopField% 
        IfNotExist, %Var_CpBase%
        {
            FileCreateDir, %VAr_CpBase%
        }    
        If ErrorLevel
        {
            Var_Location = %Var_Location%`r`n Error: Could not create destination directory: %Var_CpBase%
        }    
    } 
} 
Var_CpBase = 
Var_LRelPath = 
Return 

; ----------------------------------------------------- 
; Force Full Backup 
; ----------------------------------------------------- 
Sub_FullBackup: 
Var_doforce = 1 
Var_Pbar = 1
Var_Complete = 1
Gosub, Sub_Backup 
Var_doforce = 0 
Var_Pbar = 0
Var_Complete = 0
Return

; ----------------------------------------------------- 
; Start Incremental Backup 
; -----------------------------------------------------
#b::
Sub_IncBackup:
Var_Pbar = 1
Var_Complete = 1
Gosub, Sub_Backup 
Var_Pbar = 0
Var_Complete = 0
Return

; ----------------------------------------------------- 
; Process external file
; External file syntax example: 
; Source|Destination|Recursive|Emptyfolders|prepend|append
; ----------------------------------------------------- 
Sub_PExtFile: 
IfInString, Var_ExtFile, \
{
    Var_Temp2 = 1
}    
IfInString, Var_ExtFile, /
{
    Var_Temp2 = 1
}    
if Var_Temp2 != 1
{
    Var_ExtFile = %A_ScriptDir%\%Var_ExtFile%
}    
IfExist, %Var_ExtFile% 
{ 
    FileRead, Var_BackupInfo, %Var_ExtFile% 
    StringReplace, Var_BackupInfo, Var_BackupInfo, `r`n, ?, All 
    Notify("Lambda","Backup locations loaded.",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\backup.ico")
} 
else 
{ 
    FileAppend,,%Var_ExtFile%
    Notify("Lambda","No backup locations found. Click here to configure.",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\backup.ico AC=Sub_EditLoc")
}
return

; -----------------------------------------------------
; KeepAlive
; -----------------------------------------------------
Sub_KeepAlive:
Var_Movement = 1
if (A_TimeIdle > Var_KAIdleMax)
{
    Var_Movement := -1 * Var_Movement
    MouseMove, %Var_Movement%, 0, 0, R
    ;FileAppend, %A_Now% Mouse moved: %Var_Movement% Idle: %A_TimeIdle% Max Idle: %Var_KAIdleMax% `n, Logs\KAtest.log
}
else
{
    ;FileAppend, %A_Now% Idle: %A_TimeIdle% Max Idle: %Var_KAIdleMax% `n, Logs\KAtest.log
}
Return

; -----------------------------------------------------
; Startup
; -----------------------------------------------------
Sub_Startup:
IfNotExist, %Var_Settings%
{
    GoSub, Sub_GenIni
    Reload
}
Gosub, Sub_AddtoStart
Gosub, Sub_BackupToggle
Gosub, Sub_KeepAliveToggle
Return

; -----------------------------------------------------
; Add to Startup Folder
; -----------------------------------------------------
Sub_AddtoStart:
Var_StartLink = %A_Startup%\%A_ScriptName%.lnk
IfNotExist, %Var_StartLink%
{
    FileCreateShortcut, %A_ScriptFullPath%, %Var_StartLink%, %A_ScriptDir%,,, %A_ScriptDir%\Icons\Lambda.ico
    Notify("Lambda","Script added to Windows Startup Folder",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175  SI_=500 Image=Icons\Lambda.ico")
}
Return

; -----------------------------------------------------
; Backup Toggle
; -----------------------------------------------------
Sub_BackupToggle:
if (Var_BUActive = "True")
{
    Menu BackupSub, Check, Backup: (On/Off)
    Notify("Lambda","Automatic Backup: On",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\backup.ico")
    Gosub, Sub_PExtFile
    SetTimer, Sub_Backup, %Var_BackupInterval%
    Var_BUActive = False

}
else if (Var_BUActive = "False")
{
    Menu BackupSub, Uncheck, Backup: (On/Off)
    Notify("Lambda","Automatic Backup: Off",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\backup.ico")
    SetTimer, Sub_Backup, Off
    Var_BUActive = True
}
Return

; ----------------------------------------------------- 
; Edit Backup Locations 
; ----------------------------------------------------- 
Sub_EditLoc: 
IfExist, %Var_ExtFile% 
{ 
    Run, %Var_ExtFile% 
} 
else 
{ 
    FileAppend,,%Var_ExtFile%
    Run, %Var_ExtFile%
} 
Return 

; ----------------------------------------------------- 
; Show Backup Log File 
; ----------------------------------------------------- 
Sub_ShowBackupLog: 
IfExist, %Var_BackupLog% 
{ 
    Run, %Var_BackupLog% 
} 
else 
{ 
    FileAppend,,%Var_BackupLog%
    Run, %Var_BackupLog%
} 
Return 

; -----------------------------------------------------
; Keep Alive Toggle
; -----------------------------------------------------
#k::
Sub_KeepAliveToggle:
if (Var_KAActive = "True")
{
    Menu Tray, Check, Keep Alive: (On/Off)
    Notify("Lambda","Keep Alive: On",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\timer.ico")
    SetTimer, Sub_KeepAlive, %Var_KAInterval%
    Var_KAActive = False
}
else if (Var_KAActive = "False")
{
    Menu Tray, Uncheck, Keep Alive: (On/Off)
    Notify("Lambda","Keep Alive: Off",3,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175  SI_=500 Image=Icons\timer.ico")
    SetTimer, Sub_KeepAlive, Off
    Var_KAActive = True
}
Return

; -----------------------------------------------------
; Window Spy
; -----------------------------------------------------
Sub_Spy:
Run, AddOn\AU3_Spy.exe
Return

; -----------------------------------------------------
; RegExSandBox
; -----------------------------------------------------
Sub_SandBox:
Run, AddOn\RegExSandBox.exe
Return

; -----------------------------------------------------
; Edit Settings
; -----------------------------------------------------
Sub_EditSettings:
IfExist, %Var_Settings% 
{ 
    Run, %Var_Settings% 
} 
else 
{ 
    GoSub, Sub_GenIni
    Run, %Var_Settings%
} 
Return

; -----------------------------------------------------
; Edit Hotkeys
; -----------------------------------------------------
Sub_EditHotkeys:
IfExist, %Var_HotKeys% 
{ 
    Run, %Var_HotKeys% 
} 
else 
{ 
    FileAppend,,%Var_HotKeys%
    Run, %Var_HotKeys%
} 
Return 

; -----------------------------------------------------
; Edit AutoReplace
; -----------------------------------------------------
Sub_EditAutoRep:
IfExist, %Var_AutoRep% 
{ 
    Run, %Var_AutoRep% 
} 
else 
{
    FileAppend,,%Var_AutoRep%
    Run, %Var_AutoRep%
}
Return 

; -----------------------------------------------------
; Reload Script 
; -----------------------------------------------------
Sub_Reload:
Reload
Return

; ----------------------------------------------------- 
; Show Version
; ----------------------------------------------------- 
Sub_About:
Notify("Lambda", "Version " Var_Version,10,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\Lambda.ico")
Return

; -----------------------------------------------------
; Exit 
; -----------------------------------------------------
Sub_Exit:
ExitApp

; -----------------------------------------------------
; Update Check
; -----------------------------------------------------
#x::
Sub_Updatecheck:
UrlDownloadToFile, https://raw.githubusercontent.com/JasonElliottBishop/Lambda/master/Lambda.ahk, Temp\Lambda.ahk
FileRead, Var_Vercheck, Temp\Lambda.ahk
RegExMatch(Var_Vercheck, "\d+.\d+.\d+", Var_NewVer)
If Var_NewVer > %Var_Version%
{
    Notify("Lambda", "Available Update " Var_NewVer,10,"TS=11 TM=8 TF=Ariel GC_=Gray BC_=Black BW_=5 BT_=175 SI_=500 Image=Icons\Lambda.ico")
}
else
{
    MsgBox, You are currently using the most updated version!
}
return

;##################################################################################
;                          __Auto Generated Local Files__
;##################################################################################
; -----------------------------------------------------
; Generate Settings.ini
; -----------------------------------------------------
Sub_GenIni:
FileAppend,
(
[Backup]
; Determines if the backup function is active on startup.
Active=False
; Time in minutes between automatic backups.
Interval=60
; Determines the number of log entries to keep in Backup.log
MaxLogEntries=10
; Maximum age of Appended/Prepended backups (work in progress)
MaxDays=3

[KeepAlive]
; Determines if the backup function is active on startup.
Active=False
; Time in minutes between idle checks.
Interval=3
; Maximun time in minutes the computer is allowed to be idle before the mouse is moved.
MaxIdle=8
),%Var_Settings%
Return
