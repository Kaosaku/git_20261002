~F5::
    F5Count++
    ToolTip, F5キーが %F5Count% 回押されました
    SetTimer, ResetF5Count, -2000
    if (F5Count = 3)
    {
        ToolTip

        ; 範囲選択開始
        MsgBox, 範囲選択開始位置を左クリックしてください
        KeyWait, LButton, D
        MouseGetPos, x1, y1

        ; 範囲選択終了
        MsgBox, Shift を押しながら終了位置を左クリックしてください
        KeyWait, LShift, D
        KeyWait, LButton, D
        MouseGetPos, x2, y2

        ; オーバーレイ表示
        x := (x1 < x2) ? x1 : x2
        y := (y1 < y2) ? y1 : y2
        w := Abs(x2 - x1)
        h := Abs(y2 - y1)
        Gui, +AlwaysOnTop -Caption +ToolWindow
        Gui, Color, Red
        Gui, Show, x%x% y%y% w%w% h%h%, Overlay
        Sleep, 1000
        Gui, Destroy

        ; ドラッグ選択
        MouseClickDrag, left, x1, y1, x2, y2
        Sleep, 300

        ; コピー処理
        Clipboard := ""
        Send, ^c
        ClipWait, 5
        if (Clipboard = "")
        {
            MsgBox, コピーに失敗しました。クリップボードが空です。
            return
        }

        ; テキスト整形（空白行と「-」のみ行の除去）
        cleaned := ""
        Loop, Parse, Clipboard, `n, `r
        {
            line := A_LoopField
            line := RegExReplace(line, "^\s+|\s+$")
            if (line = "" || RegExMatch(line, "^-+$"))
                continue
            cleaned .= line "`r`n"
        }

        ; ファイル名生成（年月日_入力名）
        FormatTime, dateOnly,, yyyyMMdd
        InputBox, customName, ファイル名の指定, 保存する名前を入力してください：`n※自由に記入できます
        if ErrorLevel
        {
            MsgBox, 入力がキャンセルされました。
            return
        }

        ; 禁止文字除去
        forbidden := ["\\", "/", ":", "*", "?", """", "<", ">", "|"]
        for each, symbol in forbidden
            customName := StrReplace(customName, symbol)

        ; 保存パスとファイル名構築
        basePath := "C:\Users\a2020\OneDrive\デスクトップ\★AHK_20250713"
        filename := dateOnly "_" customName
        filepath_txt := basePath "\" filename ".txt"
        filepath_html := basePath "\" filename ".html"

        ; メモ帳起動 → 貼り付け → 保存
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

        ; HTMLファイル生成（TXT保存後に実施）
        FileAppend, <html><body><pre>%cleaned%</pre></body></html>, %filepath_html%

        ; 空ファイル作成（VSCode用）
        tempPath := A_Temp "\AHK_temp_" . A_Now . ".txt"
        FileAppend,, %tempPath%  ; 空ファイル作成

        ; VSCode起動（新規ウィンドウ＆空ファイル指定）
        Run, "C:\Users\a2020\AppData\Local\Programs\Microsoft VS Code\Code.exe" --new-window "%tempPath%"
        WinWaitActive, ahk_exe Code.exe,, 10
        Sleep, 1500  ; ウィンドウ安定化のための余裕時間を増加

        ; 整形テキストを貼り付け（保存せず表示のみ）
        Clipboard := cleaned
        Sleep, 300
        Send, ^a
        Send, {Del}
        Sleep, 300
        Send, ^v

        ; 完了通知（MsgBoxを保持）
        MsgBox, 完了しました: `nTXT保存: %filepath_txt%`nHTML生成: %filepath_html%`nVSCODEへ貼り付け完了
    }
return

ResetF5Count:
    F5Count := 0
return
