F5::

    F5Count++
    ToolTip, F5キーが %F5Count% 回押されました
    SetTimer, ResetF5Count, -2000
    if (F5Count = 3)
    {
        ToolTip

        if WinActive("ahk_class XLMAIN")
        {
            ; Excelモード
            MsgBox, Excelモードで実行します（選択済みセルをコピーします）

            Clipboard := ""
            Send, ^c
            ClipWait, 5
            if (Clipboard = "")
            {
                MsgBox, コピーに失敗しました。クリップボードが空です。
                return
            }
        }
        else
        {
            ; 通常モード（範囲指定）
            MsgBox, 範囲選択開始位置を左クリックしてください
            KeyWait, LButton, D
            MouseGetPos, x1, y1

            MsgBox, Shift を押しながら終了位置を左クリックしてください
            KeyWait, LShift, D
            KeyWait, LButton, D
            MouseGetPos, x2, y2

            x := (x1 < x2) ? x1 : x2
            y := (y1 < y2) ? y1 : y2
            w := Abs(x2 - x1)
            h := Abs(y2 - y1)

            Gui, +AlwaysOnTop -Caption +ToolWindow
            Gui, Color, Red
            Gui, Show, x%x% y%y% w%w% h%h%, Overlay
            Sleep, 1000
            Gui, Destroy

            MouseClickDrag, left, x1, y1, x2, y2
            Sleep, 300

            Clipboard := ""
            Send, ^c
            ClipWait, 5
            if (Clipboard = "")
            {
                MsgBox, コピーに失敗しました。クリップボードが空です。
                return
            }
        }

        ; 以下：整形・保存・VSCode表示処理（共通）
        cleaned := ""
        Loop, Parse, Clipboard, `n, `r
        {
            line := A_LoopField
            line := RegExReplace(line, "^\s+|\s+$")
            if (line = "" || RegExMatch(line, "^-+$"))
                continue
            cleaned .= line "`r`n"
        }

        FormatTime, dateOnly,, yyyyMMdd
        InputBox, customName, ファイル名の指定, 保存する名前を入力してください：`n※自由に記入できます
        if ErrorLevel
        {
            MsgBox, 入力がキャンセルされました。
            return
        }

        forbidden := ["\\", "/", ":", "*", "?", """", "<", ">", "|"]
        for each, symbol in forbidden
            customName := StrReplace(customName, symbol)

        basePath := "C:\Users\a2020\OneDrive\デスクトップ\★AHK_20250713"
        filename := dateOnly "_" customName
        filepath_txt := basePath "\" filename ".txt"
        filepath_html := basePath "\" filename ".html"

        Run, notepad.exe
        WinWaitActive, ahk_class Notepad
        Sleep, 300
        Send, ^a
        Send, {Del}
        Sleep, 200
        Clipboard := cleaned
        Send, ^v
        Sleep, 300
        Send, ^s
        Sleep, 500
        WinWaitActive, 名前を付けて保存,, 5
        if !WinActive("名前を付けて保存")
        {
            MsgBox, メモ帳：保存ダイアログが表示されませんでした。
            return
        }
        SendInput, %filepath_txt%
        Sleep, 300
        Send, {Enter}
        Sleep, 300
        WinClose, ahk_class Notepad

        FileAppend, <html><body><pre>%cleaned%</pre></body></html>, %filepath_html%

        tempPath := A_Temp "\AHK_temp_" . A_Now . ".txt"
        FileAppend,, %tempPath%

        Run, "C:\Users\a2020\AppData\Local\Programs\Microsoft VS Code\Code.exe" --new-window "%tempPath%"
        WinWaitActive, ahk_exe Code.exe,, 10
        Sleep, 1500
        Clipboard := cleaned
        Sleep, 300
        Send, ^a
        Send, {Del}
        Sleep, 300
        Send, ^v

        MsgBox, 完了しました: `nTXT保存: %filepath_txt%`nHTML生成: %filepath_html%`nVSCODEへ貼り付け完了
    }
return

ResetF5Count:
    F5Count := 0
return
