#Persistent
#NoEnv
toggleV := false
toggleF3F4 := false
toggleRecording := false
toggleClickReplay := false
togglePixelCheck := false

clicks := []
savedX := 0  
savedY := 0
savedColor := 0

percentThreshold := 0.30  ; Порог чувствительности цвета

; ====== ФУНКЦИИ ======
CheckColorDifference(color1, color2) {
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF

    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF

    return [Abs(r1 - r2), Abs(g1 - g2), Abs(b1 - b2), r1, g1, b1, r2, g2, b2]
}

PixelReturnedToOriginal() {
    PixelGetColor, currentColor, %savedX%, %savedY%, RGB
    diff := CheckColorDifference(savedColor, currentColor)
    return (diff[1] < diff[4] * percentThreshold) 
        and (diff[2] < diff[5] * percentThreshold) 
        and (diff[3] < diff[6] * percentThreshold)
}

; ====== ГОРЯЧИЕ КЛАВИШИ ======
Numpad1::  
    MouseGetPos, savedX, savedY
    PixelGetColor, savedColor, %savedX%, %savedY%, RGB
    Tooltip, Pixel Saved: %savedX%. %savedY%`nColor: %savedColor%
    SetTimer, RemoveTooltip, -2000
return

Numpad2::  
    toggleRecording := !toggleRecording
    clicks := toggleRecording ? [] : clicks
    Tooltip, % toggleRecording ? "Click recording started..." : "Click recording stopped."
    SetTimer, RemoveTooltip, -2000
return

~LButton::  
    if (toggleRecording) {
        MouseGetPos, clickX, clickY
        clicks.Push([clickX, clickY])
    }
return

Numpad3::  
    togglePixelCheck := !togglePixelCheck
    if (togglePixelCheck) {
        SetTimer, CheckPixel, 1000
        Tooltip, Pixel check enabled
    } else {
        SetTimer, CheckPixel, Off
        Tooltip, Pixel check disabled
    }
    SetTimer, RemoveTooltip, -2000
return

CheckPixel:
    PixelGetColor, currentColor, %savedX%, %savedY%, RGB
    diff := CheckColorDifference(savedColor, currentColor)

    if ((diff[1] >= diff[4] * percentThreshold) 
     or (diff[2] >= diff[5] * percentThreshold) 
     or (diff[3] >= diff[6] * percentThreshold)) {
        togglePixelCheck := false
        SetTimer, CheckPixel, Off
        Tooltip, Pixel changed! Starting clicks...
        SetTimer, RemoveTooltip, -2000
        toggleClickReplay := true
        SetTimer, ReplayClicks, 1000
    }
return

Numpad4::  
    if (clicks.MaxIndex() > 0) {
        toggleClickReplay := true
        SetTimer, ReplayClicks, 1000
        Tooltip, Playing recorded clicks...
    } else {
        Tooltip, No recorded clicks
    }
    SetTimer, RemoveTooltip, -2000
return

Numpad5::  
    toggleClickReplay := false
    togglePixelCheck := false
    SetTimer, ReplayClicks, Off
    SetTimer, CheckPixel, Off
    Tooltip, Click replay and pixel check disabled
    SetTimer, RemoveTooltip, -2000
return

ReplayClicks:
    if (clicks.MaxIndex() > 0) {
        Loop, % clicks.MaxIndex() {
            clickX := clicks[A_Index][1]
            clickY := clicks[A_Index][2]
            Tooltip, Click #%A_Index%: %clickX%, %clickY%
            MouseMove, %clickX%, %clickY%, 0
            Click, %clickX%, %clickY%
            Sleep, 500
        }
        
        SetTimer, RemoveTooltip, -2000
        toggleClickReplay := false
        SetTimer, ReplayClicks, Off  

        if (PixelReturnedToOriginal()) {
            Tooltip, Pixel returned to initial state. Resuming color check...
            SetTimer, CheckPixel, 1000
        }
    } else {
        Tooltip, No recorded clicks
        SetTimer, RemoveTooltip, -2000
        toggleClickReplay := false
        SetTimer, ReplayClicks, Off  
    }
return

Numpad6::  
    toggleF3F4 := !toggleF3F4
    if (toggleF3F4) {
        SetTimer, PressKeys, 1000
        Tooltip, F3-F4 enabled
    } else {
        SetTimer, PressKeys, Off
        Tooltip, F3-F4 disabled
    }
    SetTimer, RemoveTooltip, -2000
return


PressKeys:
    Send, {F3}  
    Sleep, 500
    Send, {F4}  
return

Numpad7::  
    toggleV := !toggleV
    if (toggleV) {
        SetTimer, PressV, 3000
        Tooltip, V enabled
    } else {
        SetTimer, PressV, Off
        Tooltip, V disabled
    }
    SetTimer, RemoveTooltip, -2000
return


PressV:
    Send, {v down}  
    Sleep, 50       
    Send, {v up}    
return

toggleStatus := false

Numpad8::  
    toggleStatus := !toggleStatus
    if (toggleStatus) {
        SetTimer, UpdateStatus, 1000
        Tooltip, Status Display Enabled, 100, 50
    } else {
        SetTimer, UpdateStatus, Off
        Tooltip
    }
    SetTimer, RemoveTooltip, -2000
return


RemoveTooltip:
    Tooltip
return

UpdateStatus:
    if (!toggleStatus)
        return

    statusText := ""

    ; Активные процессы
    if (toggleRecording)
        statusText .= "Recording Clicks`n"
    if (togglePixelCheck)
        statusText .= "Pixel Check Active`n"
    if (toggleClickReplay)
        statusText .= "Replaying Clicks`n"
    if (toggleF3F4)
        statusText .= "F3-F4 Active`n"
    if (toggleV)
        statusText .= "V Pressing Active`n"

    ; Сохранённый пиксель
    if (savedX != 0 && savedY != 0)
        statusText .= "Saved Pixel: (" savedX ", " savedY ") Color: " savedColor "`n"

    ; Сохранённые клики
    if (clicks.MaxIndex() > 0) {
        statusText .= "Recorded Clicks:`n"
        Loop, % clicks.MaxIndex() {
            statusText .= "#" A_Index ": (" clicks[A_Index][1] ", " clicks[A_Index][2] ")`n"
        }
    }

    if (statusText != "")
        Tooltip, %statusText%, 200, 30
    else
        Tooltip
return
