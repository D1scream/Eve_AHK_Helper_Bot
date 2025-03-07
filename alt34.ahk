#Persistent
#NoEnv
toggleV := false
toggleF3F4 := false
toggleRecording := false
toggleClickReplay := false
togglePixelCheck := false
togglePixel2Check := false

clicks := []
savedX := 0  
savedY := 0
savedColor := 0
savedX2 := 0 
savedY2 := 0
savedColor2 := 0 

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


; ====== ГОРЯЧИЕ КЛАВИШИ ======
Numpad1::  
    MouseGetPos, savedX, savedY
    PixelGetColor, savedColor, %savedX%, %savedY%, RGB
    Tooltip, Pixel Saved: %savedX%. %savedY%nColor: %savedColor%
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
        SetTimer, DoOneClickRound, 1000
    }
return

DoOneClickRound:
    if (clicks.MaxIndex() > 0) {
        Loop, % clicks.MaxIndex() {
            clickX := clicks[A_Index][1]
            clickY := clicks[A_Index][2]
            MouseMove, %clickX%, %clickY%, 0
            Click, %clickX%, %clickY%
            Sleep, 500
        }

        SetTimer, RemoveTooltip, -2000

    } else {
        Tooltip, No recorded clicks
        SetTimer, RemoveTooltip, -2000
        toggleClickReplay := false
        SetTimer, DoOneClickRound, Off  
    }
return

	

Numpad4::  
    if (clicks.MaxIndex() > 0) {
        Gosub, DoOneClickRound
        Tooltip, Playing recorded clicks...
    } else {
        Tooltip, No recorded clicks
    }
    SetTimer, RemoveTooltip, -2000
return


Numpad5::  
    toggleClickReplay := false
    togglePixelCheck := false
    SetTimer, DoOneClickRound, Off
    SetTimer, CheckPixel, Off
    Tooltip, Click replay and pixel check disabled
    SetTimer, RemoveTooltip, -2000
return


Numpad6::  
    if (clicks.MaxIndex() > 0) {
		toggleClickReplay := !toggleClickReplay
        if (toggleClickReplay) {
            Tooltip, Playing recorded clicks...
            SetTimer, DoOneClickRound, 100 
        } else {
            Tooltip, Click replay stopped.
            SetTimer, DoOneClickRound, Off
        }
    } else {
        Tooltip, No recorded clicks
		toggleClickReplay=false
    }
    SetTimer, RemoveTooltip, -2000
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

Numpad0::  
    toggleF := !toggleF
    if (toggleF) {
        SetTimer, PressFKeys, 1000 
        Tooltip, F4 and F3 enabled
    } else {
        SetTimer, PressFKeys, Off
        Tooltip, F4 and F3 disabled
    }
    SetTimer, RemoveTooltip, -2000
return

PressFKeys:
    Send, {F4}  
    Sleep, 50
    Send, {F3}  
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

Numpad9::  ; Запуск проверки пеленгатора
    togglePixel2Check := !togglePixel2Check
    if (togglePixel2Check) {
        SetTimer, CheckPixel2, 1000
        Tooltip, Pelengator check enabled
    } else {
        SetTimer, CheckPixel2, Off
        Tooltip, Pelengator check disabled
    }
    SetTimer, RemoveTooltip, -2000
return

GetAverageColor(x, y) {
    totalR := 0
    totalG := 0
    totalB := 0
    pixelCount := 0

	Loop, 5 {
		yOffset := y + A_Index - 1
		Loop, 5 {
			innerIndex := A_Index
			xOffset := x + innerIndex - 1 

			PixelGetColor, currentColor, %xOffset%, %yOffset%, RGB
			if (!ErrorLevel) {
				r := (currentColor >> 16) & 0xFF
				g := (currentColor >> 8) & 0xFF
				b := currentColor & 0xFF

				totalR += r
				totalG += g
				totalB += b
				pixelCount++
			}
		}
	}

    ; Вычисляем усреднённый цвет
    if (pixelCount > 0) {
        avgR := totalR // pixelCount
        avgG := totalG // pixelCount
        avgB := totalB // pixelCount

        ; Возвращаем усреднённый цвет в формате RGB
        return (avgR << 16) | (avgG << 8) | avgB
    } else {
        return 0
    }
}

CheckPixel2:
    currentColor2 := GetAverageColor(savedX2, savedY2)
    diff := CheckColorDifference(savedColor2, currentColor2)
    if ((diff[1] >= diff[4] * percentThreshold) 
     or (diff[2] >= diff[5] * percentThreshold) 
     or (diff[3] >= diff[6] * percentThreshold)) {
        Tooltip, Second pixel changed! Beep!
        SoundBeep, 659, 500  ; Издаем звуковой сигнал
        SetTimer, RemoveTooltip, -2000
    }
return

NumpadSub::  ; Запись цвета пеленгатора из уже сохранённых координат
    savedColor2 := GetAverageColor(savedX2, savedY2)
    Tooltip, Second Pixel Color: %savedColor2%
    SetTimer, RemoveTooltip, -2000
return

NumpadAdd::  ; Запись координат для пеленгатора
    MouseGetPos, savedX2, savedY2
    Tooltip, Second Pixel Coordinates: (%savedX2%. %savedY2%)
    SetTimer, RemoveTooltip, -2000
return

RemoveTooltip:
    Tooltip
return

UpdateStatus:
    if (!toggleStatus)
        return

    statusText := ""

    ; Заголовок для активных процессов
    statusText .= "=== Active Processes ===`n"
    if (toggleRecording)
        statusText .= "Recording Clicks`n"
    if (togglePixelCheck)
        statusText .= "Pixel Check Active`n"
    if (togglePixel2Check)
        statusText .= "Second Pixel Check Active`n"
    if (toggleClickReplay)
        statusText .= "Replaying Clicks`n"
    if (toggleF3F4)
        statusText .= "F3-F4 Active`n"
    if (toggleV)
        statusText .= "V Pressing Active`n"

    statusText .= "`n"

    ; Заголовок для сохранённых пикселей
    statusText .= "=== Saved Pixels ===`n"
    if (savedX != 0 && savedY != 0)
        statusText .= "Saved Pixel: (" savedX ", " savedY ") Color: " savedColor "`n"
    if (savedX2 != 0 && savedY2 != 0)
        statusText .= "Saved Pixel 2: (" savedX2 ", " savedY2 ") Color: " savedColor2 "`n"

    if (statusText != "")
        Tooltip, %statusText%, 200, 30
    else
        Tooltip 
return
