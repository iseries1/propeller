{{ 
File.......... VizicSmartGPU2LCDTest.spin
Purpose....... Test code for the various methods of the SW interface to the
               Vizic SmartGPU2 family of LCDs
Author........ Jim Edwards
E-mail........ jim.edwards4@comcast.net
History....... v1.0 - Initial release
Copyright..... Copyright (c) 2015 Jim Edwards
Terms......... See end of file for terms of use
}}

OBJ
  Delay         : "Clock"
  Fmt           : "Format" 
  Lcd           : "VizicSmartGPU2LCD"
  
CON

  ' General constants
  
  _CLKMODE                  = XTAL1 + PLL16X                        
  _XINFREQ                  = 5_000_000
  TestSD                    = TRUE                        ' Set false if hardware doesn't have micro SD card.
  TestAudio                 = TRUE                        ' Set false if hardware doesn't have speaker and/or a test audio WAV file stored on the micro SD card.
  AudioBoost                = TRUE                        ' Set false for no audio boost (recommended for headphones) or true for audio boost (recommended for speakers with amplifiers)
  TestImage                 = TRUE                        ' Set false if there are no test image files stored on the micro SD card.
  TestText                  = TRUE                        ' Set false if there isn't a test text file stored on the micro SD card.
  TestVideo                 = TRUE                        ' Set false if there isn't a test video file stored on the micro SD card.
  TestRTC                   = FALSE                       ' Set false if there is no crystal and backup battery installed for the real-time clock.
  TestDebug                 = FALSE                       ' Set true if verbose debug output to be generated.
  MinSongDuration           = 40                          ' Sample song should be at least this number of seconds to test all audio commands.
  SmallTextFontSize         = 0
  NormalTextFontSize        = 1
  DefaultTextFontSize       = NormalTextFontSize
   
VAR
  byte strbuf1[Lcd#FileDirNameMaxChars]                   ' Text buffer for assembling formatted strings.
  byte strbuf2[Lcd#FileDirNameMaxChars]                   ' Text buffer for assembling formatted strings.
  word image_rgb565[256]                                  ' Image pixel buffer used to write to internal display memory in RG565 format. Must be greater than or equal to 256.
  byte image_rgb888[768]                                  ' Image pixel buffer used to read from internal display memory in RGB888 format. Must be greater than or equal to 768.

DAT

  ImageBMPFileName1Str      byte "owl", 0
  ImageBMPFileName2Str      byte "supra text yellow on black 240x320", 0
  ImageJPGFileName1Str      byte "penguins", 0
  AudioWAVFileName1Str      byte "SamplePcm8bit8KhzMono", 0   ' Song should be at least MinSongDuration seconds to test all audio commands. Note that the file must be RIFF-WAV format, LPCM, 8/16 bit, up to 48KHz.
  VideoFileNameStr          byte "bee collecting honey", 0
  TextFileNameStr           byte "test", 0
        
PUB DisplayTests 

  DisplaySetup(TRUE)
  TestEraseBackgroundColor
  Delay.PauseSec(1)
  TestDisplayOrientation
  Delay.PauseSec(1) 
  TestDisplayBrightness
  Delay.PauseSec(1)
  TestSleep
  Delay.PauseSec(1)
  
  TestPutPixel
  Delay.PauseSec(1)
  TestDrawLine
  Delay.PauseSec(1)
  TestDrawRectangle
  Delay.PauseSec(1)
  TestDrawRoundRectangle
  Delay.PauseSec(1)
  TestDrawGradientRectangle
  Delay.PauseSec(1)
  TestDrawArc
  Delay.PauseSec(1)
  TestDrawCircle
  Delay.PauseSec(1)
  TestDrawEllipse
  Delay.PauseSec(1)
  TestDrawTriangle
  Delay.PauseSec(1)
  
  TestPutLetter
  Delay.PauseSec(1)
  TestDisplayNumber
  Delay.PauseSec(1)
  if (TestSD AND TestText)
    TestDisplayPrintSD
    Delay.PauseSec(1)
    
  TestDrawImage
  Delay.PauseSec(1)
  if (TestSD AND TestImage)
    TestImageBMPSD
    Delay.PauseSec(1)
    TestImageJPGSD
    Delay.PauseSec(1)
    TestScreenshotBMP
    Delay.PauseSec(1)
  TestReadMemoryImage
  Delay.PauseSec(1)

  if (TestSD AND TestVideo)
    TestVideoCommands
    Delay.PauseSec(1)
    
  if (TestSD AND TestAudio)
    TestAudioCommands
    Delay.PauseSec(1)
    
  TestGetTouchscreen
  Delay.PauseSec(1)
  TestGetTouchIcons
  Delay.PauseSec(1)
  
  if (TestSD)
    TestFatCommands
    Delay.PauseSec(1)
  
  if (TestRTC)
    TestRtcCommands
    Delay.PauseSec(1)
    
  TestEEPromFlashCommands
  Delay.PauseSec(1)

  TestObjectCheckbox
  Delay.PauseSec(1)
  TestObjectButton
  Delay.PauseSec(1)
  TestObjectSwitch
  Delay.PauseSec(1)
  TestObjectProgressBar
  Delay.PauseSec(1)
  TestObjectScrollBar
  Delay.PauseSec(1)
  TestObjectSliderBar
  Delay.PauseSec(1)
  TestObjectWindow
  Delay.PauseSec(1)
  DisplaySetup(FALSE)
  DisplayTestTitle(string("Complete!"), 0)
  repeat

PRI WaitForTouchPressRelease | x, y
  repeat until Lcd.SG2GetTouchscreen(@x, @y)
  Delay.PauseMSec(100)
  repeat until NOT Lcd.SG2GetTouchscreen(@x, @y)
  Delay.PauseMSec(100)
  
PRI DisplaySetup(init_enable)

  if (init_enable)
    Lcd.SG2DisplayStartup(FALSE)
  Lcd.DisplaySetErrorCheckingOn
  Lcd.SG2DisplayOrientation(Lcd#OrientationVerticalBottom)
  Lcd.SG2DisplayBrightness(100)
  Lcd.SG2SetTextFontColour($FF, $FF, $FF)  ' White 
  Lcd.SG2SetTextFontSize(DefaultTextFontSize)
  Lcd.SG2SetTextBackgroundColour($00, $00, $00)  ' Black    
  Lcd.SG2SetTextBackgroundMode(Lcd#FillModeFilled)
  Lcd.SG2SetEraseBackgroundColour($00, $00, $00)  ' Black  
  Lcd.SG2EraseScreen

PRI DisplayTestTitle(title_str_addr, pause_secs) | num_printed

  Lcd.SG2EraseScreen
  Lcd.SG2SetTextFontColour($FF, $FF, $FF)  ' White
  Lcd.SG2DisplayString(0, 0, 239, 239, string("TEST:"), @num_printed)
  Lcd.SG2SetTextFontColour($FF, $FF, $00)  ' Yellow
  Lcd.SG2DisplayString(0, 20, 239, 239, title_str_addr, @num_printed)
  Delay.PauseSec(pause_secs)
  
PRI DisplayTestTitleFull(title_str_addr, r_test, g_test, b_test, r_title, g_title, b_title, pause_secs) | num_printed

  Lcd.SG2EraseScreen
  Lcd.SG2SetTextFontColour(r_test, g_test, b_test)
  Lcd.SG2DisplayString(0, 0, 239, 239, string("TEST:"), @num_printed) 
  Lcd.SG2SetTextFontColour(r_title, g_title, b_title)
  Lcd.SG2DisplayString(0, 20, 239, 239, title_str_addr, @num_printed)
  Delay.PauseSec(pause_secs)

PRI TestEraseBackgroundColor  | num_printed

  DisplayTestTitle(string("EraseBackgroundColor"), 2)
  Lcd.SG2SetTextBackgroundMode(Lcd#FillModeUnfilled)
   
  Lcd.SG2SetEraseBackgroundColour($00, $FF, $00)  ' Green
  Lcd.SG2EraseScreen
  DisplayTestTitleFull(string("EraseBackgroundColor"), $00, $00, $00, $00, $00, $00, 0)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("GREEN"), @num_printed)
  Delay.PauseSec(1)  

  Lcd.SG2SetEraseBackgroundColour($FF, $FF, $00)  ' Yellow
  Lcd.SG2EraseScreen
  DisplayTestTitleFull(string("EraseBackgroundColor"), $00, $00, $00, $00, $00, $00, 0)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("YELLOW"), @num_printed)
  Delay.PauseSec(1)  

  Lcd.SG2SetEraseBackgroundColour($FF, $00, $00)  ' Red
  Lcd.SG2EraseScreen
  DisplayTestTitleFull(string("EraseBackgroundColor"), $00, $00, $00, $00, $00, $00, 0)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("RED"), @num_printed)
  Delay.PauseSec(1)  
  DisplaySetup(FALSE)

PRI TestDisplayOrientation | num_printed
 
  Lcd.SG2DisplayOrientation(Lcd#OrientationVerticalBottom)
  DisplayTestTitle(string("DisplayOrientation"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Portrait"), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("LCD connector on bottom"), @num_printed)
  Delay.PauseSec(2)  

  Lcd.SG2DisplayOrientation(Lcd#OrientationHorizontalRight)
  DisplayTestTitle(string("DisplayOrientation"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Landscape"), @num_printed)    
  Lcd.SG2DisplayString(0, 60, 239, 239, string("LCD connector on right"), @num_printed)
  Delay.PauseSec(2)

  Lcd.SG2DisplayOrientation(Lcd#OrientationVerticalTop)
  DisplayTestTitle(string("DisplayOrientation"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Portrait"), @num_printed) 
  Lcd.SG2DisplayString(0, 60, 239, 239, string("LCD connector on top"), @num_printed)
  Delay.PauseSec(2)

  Lcd.SG2DisplayOrientation(Lcd#OrientationHorizontalLeft)
  DisplayTestTitle(string("DisplayOrientation"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Landscape"), @num_printed) 
  Lcd.SG2DisplayString(0, 60, 239, 239, string("LCD connector on left"), @num_printed)
  Delay.PauseSec(2)
  DisplaySetup(FALSE)

PRI TestDisplayBrightness | brightness

  DisplayTestTitle(string("DisplayBrightness"), 0)
  Lcd.SG2SetTextBackgroundMode(Lcd#FillModeUnfilled) 
  Lcd.SG2SetEraseBackgroundColour($FF, $FF, $00)  ' Yellow
  Lcd.SG2EraseScreen
  DisplayTestTitleFull(string("DisplayBrightness"), $00, $00, $00, $00, $00, $00, 1) 
  repeat brightness from 100 to 0 step 10
    Lcd.SG2DisplayBrightness(brightness)
    Delay.PauseMSec(200)  
  DisplaySetup(FALSE)

PRI TestSleep | num_printed, start_time

  DisplayTestTitle(string("DisplaySleep"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Sleep turned ON"), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("in 8 seconds."), @num_printed)   
  Lcd.SG2DisplayString(0, 80, 239, 239, string("Screen will go white."), @num_printed)      
  Lcd.SG2DisplayString(0, 100, 239, 239, string("And then Sleep"), @num_printed)
  Lcd.SG2DisplayString(0, 120, 239, 239, string("turned OFF"), @num_printed)
  Lcd.SG2DisplayString(0, 140, 239, 239, string("4 seconds later."), @num_printed)
  start_time := cnt
  repeat
    Fmt.sprintf(@strbuf1, string("Countdown = %d Secs"), (cnt - start_time) / clkfreq)
    Lcd.SG2DisplayString(0, 160, 239, 239, @strbuf1, @num_printed) 
  until ((cnt - start_time) => (8 * clkfreq))
  Lcd.SG2Sleep(Lcd#SleepOn)
  Delay.PauseSec(4)    
  Lcd.SG2Sleep(Lcd#SleepOff)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestPutPixel | x

  DisplayTestTitle(string("PutPixel"), 0)
  repeat x from 0 to 235 step 30
    Lcd.SG2PutPixel(x, 60, $FF, $00, $00)    ' Red
    Lcd.SG2PutPixel(x+1, 60, $FF, $00, $00)
    Lcd.SG2PutPixel(x+5, 60,$00, $FF, $00)   ' Green
    Lcd.SG2PutPixel(x+6, 60, $00, $FF, $00)
    Lcd.SG2PutPixel(x+10, 60, $00, $00, $FF) ' Blue
    Lcd.SG2PutPixel(x+11, 60, $00, $00, $FF)
    Lcd.SG2PutPixel(x+15, 60, $FF, $FF, $00) ' Yellow
    Lcd.SG2PutPixel(x+16, 60, $FF, $FF, $00)
    Lcd.SG2PutPixel(x+20, 60, $00, $FF, $FF) ' Aqua
    Lcd.SG2PutPixel(x+21, 60, $00, $FF, $FF)
    Lcd.SG2PutPixel(x+25, 60, $FF, $00, $FF) ' Fuchsia
    Lcd.SG2PutPixel(x+26, 60, $FF, $00, $FF)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)
    
PRI TestDrawLine | x

  DisplayTestTitle(string("DrawLine"), 0) 
  repeat x from 0 to 235 step 30
    Lcd.SG2DrawLine(x, 60, x, 260, $FF, $00, $00)       ' Red
    Lcd.SG2DrawLine(x+1, 60, x+1, 260, $FF, $00, $00)
    Lcd.SG2DrawLine(x+5, 60, x+5, 260, $00, $FF, $00)   ' Green
    Lcd.SG2DrawLine(x+6, 60, x+6, 260, $00, $FF, $00)
    Lcd.SG2DrawLine(x+10, 60, x+10, 260, $00, $00, $FF) ' Blue
    Lcd.SG2DrawLine(x+11, 60, x+11, 260, $00, $00, $FF)
    Lcd.SG2DrawLine(x+15, 60, x+15, 260, $FF, $FF, $00) ' Yellow
    Lcd.SG2DrawLine(x+16, 60, x+16, 260, $FF, $FF, $00)
    Lcd.SG2DrawLine(x+20, 60, x+20, 260, $00, $FF, $FF) ' Aqua
    Lcd.SG2DrawLine(x+21, 60, x+21, 260, $00, $FF, $FF)
    Lcd.SG2DrawLine(x+25, 60, x+25, 260, $FF, $00, $FF) ' Fuchsia
    Lcd.SG2DrawLine(x+26, 60, x+26, 260, $FF, $00, $FF)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDrawRectangle | num_printed

  DisplayTestTitle(string("DrawRectangle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Unfilled"), @num_printed)
  Lcd.SG2DrawRectangle(0, 60, 120, 180, $FF, $00, $00, Lcd#FillModeUnfilled)  ' Red
  Lcd.SG2DrawRectangle(20, 80, 100, 160, $00, $FF, $00, Lcd#FillModeUnfilled)  ' Green
  Lcd.SG2DrawRectangle(40, 100, 80, 140, $00, $00, $FF, Lcd#FillModeUnfilled)  ' Blue 
  Delay.PauseSec(1)

  DisplayTestTitle(string("DrawRectangle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Filled"), @num_printed)
  Lcd.SG2DrawRectangle(0, 60, 120, 180, $FF, $00, $00, Lcd#FillModeFilled)  ' Red
  Lcd.SG2DrawRectangle(20, 80, 100, 160, $00, $FF, $00, Lcd#FillModeFilled)  ' Green
  Lcd.SG2DrawRectangle(40, 100, 80, 140, $00, $00, $FF, Lcd#FillModeFilled)  ' Blue 
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDrawRoundRectangle | num_printed

  DisplayTestTitle(string("DrawRoundRectangle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Unfilled"), @num_printed)
  Lcd.SG2DrawRoundRectangle(0, 60, 120, 180, 12, $FF, $00, $00, Lcd#FillModeUnfilled)  ' Red
  Lcd.SG2DrawRoundRectangle(20, 80, 100, 160, 6, $00, $FF, $00, Lcd#FillModeUnfilled)  ' Green
  Lcd.SG2DrawRoundRectangle(40, 100, 80, 140, 4, $00, $00, $FF, Lcd#FillModeUnfilled)  ' Blue 
  Delay.PauseSec(1)

  DisplayTestTitle(string("DrawRoundRectangle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Filled"), @num_printed)
  Lcd.SG2DrawRoundRectangle(0, 60, 120, 180, 12, $FF, $00, $00, Lcd#FillModeFilled)  ' Red
  Lcd.SG2DrawRoundRectangle(20, 80, 100, 160, 6, $00, $FF, $00, Lcd#FillModeFilled)  ' Green
  Lcd.SG2DrawRoundRectangle(40, 100, 80, 140, 4, $00, $00, $FF, Lcd#FillModeFilled)  ' Blue 
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDrawGradientRectangle | num_printed

  DisplayTestTitle(string("DrawGradientRectangle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Horizontal red to blue"), @num_printed)
  Lcd.SG2DrawGradientRectangle(0, 60, 239, 130, $FF, $00, $00, $00, $00, $FF, Lcd#DirectionHorizontal)  ' Horizontal red to blue gradient
  Lcd.SG2DisplayString(0, 140, 239, 239, string("Vertical green to yellow"), @num_printed) 
  Lcd.SG2DrawGradientRectangle(0, 160, 239, 230, $00, $FF, $00, $FF, $FF, $00, Lcd#DirectionVertical)  ' Vertical green to yellow gradient
  Delay.PauseSec(2)

PRI TestDrawArc | num_printed

  DisplayTestTitle(string("DrawArc"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Unfilled"), @num_printed)
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantNorthEast, $FF, $00, $00, Lcd#FillModeUnfilled)  ' Red
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantNorthWest, $00, $FF, $00, Lcd#FillModeUnfilled)  ' Green
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantSouthWest, $00, $00, $FF, Lcd#FillModeUnfilled)  ' Blue
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantSouthEast, $FF, $FF, $00, Lcd#FillModeUnfilled)  ' Yellow
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantNorthEast, $00, $00, $FF, Lcd#FillModeUnfilled)  ' Blue
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantNorthWest, $FF, $FF, $00, Lcd#FillModeUnfilled)  ' Yellow
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantSouthWest, $FF, $00, $00, Lcd#FillModeUnfilled)  ' Red
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantSouthEast, $00, $FF, $00, Lcd#FillModeUnfilled)  ' Green  
  Delay.PauseSec(1)

  DisplayTestTitle(string("DrawArc"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Filled"), @num_printed)
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantNorthEast, $FF, $00, $00, Lcd#FillModeFilled)  ' Red
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantNorthWest, $00, $FF, $00, Lcd#FillModeFilled)  ' Green
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantSouthWest, $00, $00, $FF, Lcd#FillModeFilled)  ' Blue
  Lcd.SG2DrawArc(50, 110, 50, 50, Lcd#QuadrantSouthEast, $FF, $FF, $00, Lcd#FillModeFilled)  ' Yellow
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantNorthEast, $00, $00, $FF, Lcd#FillModeFilled)  ' Blue
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantNorthWest, $FF, $FF, $00, Lcd#FillModeFilled)  ' Yellow
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantSouthWest, $FF, $00, $00, Lcd#FillModeFilled)  ' Red
  Lcd.SG2DrawArc(50, 110, 25, 50, Lcd#QuadrantSouthEast, $00, $FF, $00, Lcd#FillModeFilled)  ' Green 
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDrawCircle | num_printed
  
  DisplayTestTitle(string("DrawCircle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Unfilled"), @num_printed)
  Lcd.SG2DrawCircle(60, 120, 60, $FF, $00, $00, Lcd#FillModeUnfilled)  ' Red
  Lcd.SG2DrawCircle(60, 120, 40, $00, $FF, $00, Lcd#FillModeUnfilled)  ' Green
  Lcd.SG2DrawCircle(60, 120, 20, $00, $00, $FF, Lcd#FillModeUnfilled)  ' Blue 
  Delay.PauseSec(1)

  DisplayTestTitle(string("DrawCircle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Filled"), @num_printed)
  Lcd.SG2DrawCircle(60, 120, 60, $FF, $00, $00, Lcd#FillModeFilled)  ' Red
  Lcd.SG2DrawCircle(60, 120, 40, $00, $FF, $00, Lcd#FillModeFilled)  ' Green
  Lcd.SG2DrawCircle(60, 120, 20, $00, $00, $FF, Lcd#FillModeFilled)  ' Blue 
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDrawEllipse | num_printed

  DisplayTestTitle(string("DrawEllipse"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Unfilled"), @num_printed)
  Lcd.SG2DrawEllipse(60, 120, 60, 60, $FF, $00, $00, Lcd#FillModeUnfilled)  ' Red
  Lcd.SG2DrawEllipse(60, 120, 60, 40, $00, $FF, $00, Lcd#FillModeUnfilled)  ' Green
  Lcd.SG2DrawEllipse(60, 120, 60, 20, $00, $00, $FF, Lcd#FillModeUnfilled)  ' Blue 
  Delay.PauseSec(1)

  DisplayTestTitle(string("DrawEllipse"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Filled"), @num_printed)
  Lcd.SG2DrawEllipse(60, 120, 60, 60, $FF, $00, $00, Lcd#FillModeFilled)  ' Red
  Lcd.SG2DrawEllipse(60, 120, 60, 40, $00, $FF, $00, Lcd#FillModeFilled)  ' Green
  Lcd.SG2DrawEllipse(60, 120, 60, 20, $00, $00, $FF, Lcd#FillModeFilled)  ' Blue 
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDrawTriangle | num_printed

  DisplayTestTitle(string("DrawTriangle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Unfilled"), @num_printed)
  Lcd.SG2DrawTriangle(60, 60, 120, 180, 0, 180, $FF, $00, $00, Lcd#FillModeUnfilled)  ' Red
  Lcd.SG2DrawTriangle(60, 90, 100, 170, 20, 170, $00, $FF, $00, Lcd#FillModeUnfilled)  ' Green
  Lcd.SG2DrawTriangle(60, 120, 80, 160, 40, 160, $00, $00, $FF, Lcd#FillModeUnfilled)  ' Blue
  Delay.PauseSec(1)

  DisplayTestTitle(string("DrawTriangle"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Mode = Filled"), @num_printed)
  Lcd.SG2DrawTriangle(60, 60, 120, 180, 0, 180, $FF, $00, $00, Lcd#FillModeFilled)  ' Red
  Lcd.SG2DrawTriangle(60, 90, 100, 170, 20, 170, $00, $FF, $00, Lcd#FillModeFilled)  ' Green
  Lcd.SG2DrawTriangle(60, 120, 80, 160, 40, 160, $00, $00, $FF, Lcd#FillModeFilled)  ' Blue
  Delay.PauseSec(1)
  DisplaySetup(FALSE)
        
PRI TestPutLetter | x_next
  DisplayTestTitle(string("PutLetter"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2PutLetter(0, 40, "H", @x_next)
  Delay.PauseMSec(200)
  Lcd.SG2PutLetter(x_next, 40, "E", @x_next)
  Delay.PauseMSec(200)    
  Lcd.SG2PutLetter(x_next, 40, "L", @x_next)
  Delay.PauseMSec(200)    
  Lcd.SG2PutLetter(x_next, 40, "L", @x_next)
  Delay.PauseMSec(200)    
  Lcd.SG2PutLetter(x_next, 40, "O", @x_next)
  Delay.PauseMSec(200)
  Lcd.SG2PutLetter(0, 60, "E", @x_next)
  Delay.PauseMSec(200)    
  Lcd.SG2PutLetter(0, 80, "L", @x_next)
  Delay.PauseMSec(200)    
  Lcd.SG2PutLetter(0, 100, "L", @x_next)
  Delay.PauseMSec(200)    
  Lcd.SG2PutLetter(0, 120, "O", @x_next)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDisplayNumber
  DisplayTestTitle(string("DisplayNumber"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayNumber(0, 40, 123456.0)
  Lcd.SG2DisplayNumber(0, 60, 1.23e5)
  Lcd.SG2DisplayNumber(0, 80, 12.578)
  Lcd.SG2DisplayNumber(0, 100, 543221568.0)
  Lcd.SG2DisplayNumber(0, 120, -23.4568)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)
  
PRI TestDisplayPrintSD | num_printed
  DisplayTestTitle(string("DisplayPrintSD"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green 
  Lcd.SG2DisplayStringSD(0, 40, 239, 239, 0, 0, @TextFileNameStr, @num_printed)  ' The quick brown fox jumps over the lazy dog
  Delay.PauseSec(2)
  DisplayTestTitle(string("DisplayPrintSD"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green 
  Lcd.SG2DisplayStringSD(0, 40, 239, 239, 4, 0, @TextFileNameStr, @num_printed)  ' quick brown fox jumps over the lazy dog
  Delay.PauseSec(2)
  DisplayTestTitle(string("DisplayPrintSD"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green 
  Lcd.SG2DisplayStringSD(0, 40, 239, 239, 4, 15, @TextFileNameStr, @num_printed)  ' quick brown fox
  Delay.PauseSec(2)
  DisplaySetup(FALSE)

PRI TestDrawImage | num_pixels, pixel_index, pixel_rgb565

  DisplayTestTitle(string("DrawImage"), 0) 
  num_pixels := 256
  pixel_rgb565 := Lcd.Red8Blue8Green8_To_Rgb565($FF, $00, $00)  ' Red
  Repeat pixel_index from 0 to (num_pixels - 1)
    image_rgb565[pixel_index] := pixel_rgb565
  Lcd.SG2DrawImage(40, 60, 55, 75, @image_rgb565)

  pixel_rgb565 := Lcd.Red8Blue8Green8_To_Rgb565($00, $FF, $00)  ' Green
  Repeat pixel_index from 0 to (num_pixels - 1)
    image_rgb565[pixel_index] := pixel_rgb565  
  Lcd.SG2DrawImage(80, 60, 95, 75, @image_rgb565)

  pixel_rgb565 := Lcd.Red8Blue8Green8_To_Rgb565($00, $00, $FF)  ' Blue
  Repeat pixel_index from 0 to (num_pixels - 1)
    image_rgb565[pixel_index] := pixel_rgb565
  Lcd.SG2DrawImage(120, 60, 135, 75, @image_rgb565)

  pixel_rgb565 := Lcd.Red8Blue8Green8_To_Rgb565($FF, $FF, $00)  ' Yellow
  Repeat pixel_index from 0 to (num_pixels - 1)
    image_rgb565[pixel_index] := pixel_rgb565
  Lcd.SG2DrawImage(160, 60, 175, 75, @image_rgb565)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)
    
PRI TestImageBMPSD
  DisplayTestTitle(string("ImageBMPSD"), 2)
  Lcd.SG2ImageBMPSD(0, 0, @ImageBMPFileName1Str)
  Delay.PauseSec(2)
  Lcd.SG2ImageBMPSD(0, 0, @ImageBMPFileName2Str)
  Delay.PauseSec(2)
  DisplaySetup(FALSE)

PRI TestImageJPGSD
  DisplayTestTitle(string("ImageJPGSD"), 2)
  Lcd.SG2DisplayOrientation(Lcd#OrientationHorizontalRight)
  Lcd.SG2ImageJPGSD(0, 0, Lcd#ScaleFactor1_1, @ImageJPGFileName1Str)
  Delay.PauseSec(2)
  Lcd.SG2EraseScreen     
  Lcd.SG2ImageJPGSD(0, 0, Lcd#ScaleFactor1_2, @ImageJPGFileName1Str)
  Delay.PauseSec(2)
  Lcd.SG2EraseScreen     
  Lcd.SG2ImageJPGSD(0, 0, Lcd#ScaleFactor1_4, @ImageJPGFileName1Str)
  Delay.PauseSec(2)
  Lcd.SG2EraseScreen     
  Lcd.SG2ImageJPGSD(0, 0, Lcd#ScaleFactor1_8, @ImageJPGFileName1Str)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestReadMemoryImage | index, k, num_pixels, num_printed, pixel, or_val, pixel_index, pixel_rgb565_red, pixel_rgb565_green, pixel_rgb565_blue, pixel_rgb565_yellow, red_expected, green_expected, blue_expected, red_actual, green_actual, blue_actual, test_status

  DisplayTestTitle(string("ReadMemoryImage"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Loading test image"), @num_printed)  
  num_pixels := 256
  pixel_rgb565_red := Lcd.Red8Blue8Green8_To_Rgb565($FF, $00, $00)    ' Red
  pixel_rgb565_green := Lcd.Red8Blue8Green8_To_Rgb565($00, $FF, $00)  ' Green
  pixel_rgb565_blue := Lcd.Red8Blue8Green8_To_Rgb565($00, $00, $FF)   ' Blue
  pixel_rgb565_yellow := Lcd.Red8Blue8Green8_To_Rgb565($FF, $FF, $00) ' Yellow
  repeat pixel_index from 0 to (num_pixels - 1) step 4
    image_rgb565[pixel_index] := pixel_rgb565_red
    image_rgb565[pixel_index + 1] := pixel_rgb565_green
    image_rgb565[pixel_index + 2] := pixel_rgb565_blue
    image_rgb565[pixel_index + 3] := pixel_rgb565_yellow      
  Lcd.SG2DrawImage(40, 80, 55, 95, @image_rgb565)
  Delay.PauseSec(1) 

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Reading memory image  "), @num_printed)    
  Lcd.SG2ReadMemoryImage(40, 80, 55, 95, @image_rgb888)
  Delay.PauseSec(1)
  
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Testing memory image  "), @num_printed)
  Delay.PauseSec(1)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                      "), @num_printed)    
  test_status := TRUE
  pixel := 0
  red_expected := green_expected := blue_expected := 0
  red_actual := green_actual := blue_actual := 0  
  k := 0
  Repeat pixel_index from 0 to (num_pixels - 1)
    ' The SmartGPU2's rgb565 to rgb888 algorithm seems to be actually handling rgb565 as if it was rgb666 
    pixel := image_rgb565[pixel_index]
    red_expected := Lcd.Rgb565_To_Red8(pixel)
    if (red_expected & $08)
      or_val := $04
    else
      or_val := $00
    red_expected := red_expected | or_val
    green_expected := Lcd.Rgb565_To_Green8(pixel)
    blue_expected := Lcd.Rgb565_To_Blue8(pixel)
    if (blue_expected & $08)
      or_val := $04
    else
      or_val := $00
    blue_expected := blue_expected | or_val
    red_actual := image_rgb888[k++]
    green_actual := image_rgb888[k++]
    blue_actual := image_rgb888[k++]
    if (TestDebug)
      index := Fmt.bprintf(@strbuf1, 0, string("Exp Pix %d: "), pixel_index)
      index := Fmt.bprintf(@strbuf1, index, string("$%02x,"), red_expected)
      index := Fmt.bprintf(@strbuf1, index, string("$%02x,"), green_expected)
      index := Fmt.bprintf(@strbuf1, index, string("$%02x"), blue_expected)
      strbuf1[index] := 0
      Lcd.SG2DisplayString(0, 40, 239, 239, @strbuf1, @num_printed)
      index := Fmt.bprintf(@strbuf1, 0, string("Act Pix %d: "), pixel_index)
      index := Fmt.bprintf(@strbuf1, index, string("$%02x,"), red_actual)
      index := Fmt.bprintf(@strbuf1, index, string("$%02x,"), green_actual)
      index := Fmt.bprintf(@strbuf1, index, string("$%02x"), blue_actual)
      strbuf1[index] := 0
      Lcd.SG2DisplayString(0, 60, 239, 239, @strbuf1, @num_printed)
      Delay.PauseSec(2)
      Lcd.SG2DisplayString(0, 40, 239, 239, string("                          "), @num_printed)
      Lcd.SG2DisplayString(0, 60, 239, 239, string("                          "), @num_printed)     
    if ((red_actual <> red_expected) OR (green_actual <> green_expected) OR (blue_actual <> blue_expected))
      test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 40, 239, 239, string("Pass                  "), @num_printed) 
  else
    Lcd.SG2DisplayString(0, 40, 239, 239, string("Fail                  "), @num_printed)
  Delay.PauseSec(2)
  DisplaySetup(FALSE)
  
PRI TestScreenshotBMP | file_status, num_printed

  DisplayTestTitle(string("DrawImage"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Loading image file."), @num_printed)
  Delay.PauseSec(1)     
  Lcd.SG2ImageBMPSD(0, 0, @ImageBMPFileName1Str)
  Lcd.SG2ScreenshotBMP
  DisplayTestTitle(string("DrawImage"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green 
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Screenshot saved.        "), @num_printed)
  Delay.PauseSec(1) 
  DisplayTestTitle(string("DrawImage"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green 
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Loading screenshot file. "), @num_printed)
  Delay.PauseSec(1) 
  Lcd.SG2ImageBMPSD(0, 0, string("Screenshot000"))
  Lcd.SG2FatEraseDirFile(string("Screenshot000.bmp"), @file_status)  
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestVideoCommands | num_printed, width, height, frames_per_sec, num_frames, num_frames_to_play, start_frame
  DisplayTestTitle(string("VideoCommands"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Allocating video file."), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("Status:"), @num_printed)   
  Fmt.sprintf(@strbuf1, string("Name = %s.vid"), @VideoFileNameStr)
  Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed) 
  width := height := frames_per_sec := num_frames := 0
  if (Lcd.SG2AllocateVideoSD(@VideoFileNameStr, @width, @height, @frames_per_sec, @num_frames))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Status: Pass"), @num_printed)
    Fmt.sprintf(@strbuf1, string("Width = %d"), width)
    Lcd.SG2DisplayString(0, 100, 239, 239, @strbuf1, @num_printed)
    Fmt.sprintf(@strbuf1, string("Height = %d"), height)
    Lcd.SG2DisplayString(0, 120, 239, 239, @strbuf1, @num_printed)
    Fmt.sprintf(@strbuf1, string("Frames/Sec = %d"), frames_per_sec)
    Lcd.SG2DisplayString(0, 140, 239, 239, @strbuf1, @num_printed)
    Fmt.sprintf(@strbuf1, string("Num Frames = %d"), num_frames)
    Lcd.SG2DisplayString(0, 160, 239, 239, @strbuf1, @num_printed)
    Delay.PauseSec(2)
    Lcd.SG2DisplayString(0, 40, 239, 239, string("Setting start frame.   "), @num_printed)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Status:       "), @num_printed)
    Delay.PauseSec(2)
    start_frame := 100
    num_frames_to_play := 100  ' This should be 5 seconds
    if (Lcd.SG2SetFrameVideoSD(start_frame))
      Lcd.SG2DisplayString(0, 60, 239, 239, string("Status: Pass"), @num_printed)
      Delay.PauseSec(1)
      Lcd.SG2DisplayString(0, 40, 239, 239, string("Play video.            "), @num_printed)
      Lcd.SG2DisplayString(0, 60, 239, 239, string("Status:       "), @num_printed)
      Delay.PauseSec(2)
      Lcd.SG2DisplayOrientation(Lcd#OrientationHorizontalRight)
      Lcd.SG2PlayVideoSD(0, 0, num_frames_to_play)
      Delay.PauseSec(6)
      DisplaySetup(FALSE)
      DisplayTestTitle(string("VideoCommands"), 0)
      Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
      Lcd.SG2DisplayString(0, 40, 239, 239, string("Deallocating video file."), @num_printed)
      if (Lcd.SG2DeallocateVideoSD)
        Lcd.SG2DisplayString(0, 60, 239, 239, string("Status: Pass"), @num_printed)  
      else
        Lcd.SG2DisplayString(0, 60, 239, 239, string("Status: Fail"), @num_printed)
      Delay.PauseSec(1)  
    else
      Lcd.SG2DisplayString(0, 60, 239, 239, string("Status: Fail"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Status: Fail"), @num_printed) 
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestAudioCommands | audio_boost_state, duration, num_printed, state

  DisplayTestTitle(string("AudioCommands"), 0) 
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green 
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Output = Off"), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("Boost = Off"), @num_printed)
  Lcd.SG2DisplayString(0, 80, 239, 239, string("Volume = Default"), @num_printed)
  Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Unknown"), @num_printed)
  Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = N/A"), @num_printed)  
  Lcd.SG2DisplayString(0, 140, 239, 239, string("Duration = N/A"), @num_printed)
  Lcd.SG2DisplayString(0, 160, 239, 239, string("File = NONE"), @num_printed)
  Delay.PauseSec(2)  

  ' Turn Audio DAC output on.
  
  Lcd.SG2SetAudioDacState(Lcd#AudioDacOn)
  Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue  
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Output = On  "), @num_printed)
  Delay.PauseSec(2) 
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Output = On  "), @num_printed)

  ' Set audio boost to selected state.

  if (AudioBoost)
    audio_boost_state := Lcd#AudioBoostOn
  else
    audio_boost_state := Lcd#AudioBoostOff
  Lcd.SG2SetAudioBoostState(audio_boost_state)
  Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
  if (AudioBoost) 
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Boost = On  "), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Boost = Off "), @num_printed)  
  Delay.PauseSec(2)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  if (AudioBoost) 
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Boost = On  "), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Boost = Off "), @num_printed) 

  ' Set audio volume to 50%. 

  Lcd.SG2SetAudioVolume(50)
  Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
  Lcd.SG2DisplayString(0, 80, 239, 239, string("Volume = 50%     "), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 80, 239, 239, string("Volume = 50%     "), @num_printed)

  ' Get audio state. At this point it should be inactive.
  
  Lcd.SG2GetWAVPlayState(@state)
  Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
  if (state == 0)
    Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
  else 
    Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  if (state == 0)
    Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
  else 
    Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed) 

  ' Start playing a WAV file and continue only if it has the expected minimum duration. Then, check whether audio state changes as expected.
  
  Lcd.SG2PlayWAVFile(@AudioWAVFileName1Str, @duration)
  if (duration => MinSongDuration)

    ' Test play command
  
    Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
    Lcd.SG2GetWAVPlayState(@state)
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed) 
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Running"), @num_printed) 
    Fmt.sprintf(@strbuf1, string("Duration = %d seconds"), duration)
    Lcd.SG2DisplayString(0, 140, 239, 239, @strbuf1, @num_printed)
    Fmt.sprintf(@strbuf1, string("Filename = %s"), @AudioWAVFileName1Str)
    Lcd.SG2DisplayString(0, 160, 239, 239, @strbuf1, @num_printed)
    Delay.PauseSec(2)
    Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed) 
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Running"), @num_printed) 
    Fmt.sprintf(@strbuf1, string("Duration = %d seconds"), duration)
    Lcd.SG2DisplayString(0, 140, 239, 239, @strbuf1, @num_printed)
    Fmt.sprintf(@strbuf1, string("Filename = %s"), @AudioWAVFileName1Str)
    Lcd.SG2DisplayString(0, 160, 239, 239, @strbuf1, @num_printed)
    Delay.PauseSec(2)

    ' Test volume command, total play time = ~4 seconds, play position at ~4 seconds 
      
    Lcd.SG2SetAudioVolume(100)
    Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
    Lcd.SG2DisplayString(0, 80, 239, 239, string("Volume = 100%"), @num_printed)
    Delay.PauseSec(2)
    Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
    Lcd.SG2DisplayString(0, 80, 239, 239, string("Volume = 100%"), @num_printed)
    Delay.PauseSec(2)
        
    ' Test advance 20 command, check state, total play time = ~8 seconds, play position at ~8 seconds 

    Lcd.SG2AdvanceWAVFile(20)
    Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
    Lcd.SG2GetWAVPlayState(@state)
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed) 
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Advance 20"), @num_printed)  
    Delay.PauseSec(2)
    Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Running    "), @num_printed)   
    Delay.PauseSec(2)
            
    ' Test pause/stop command, check state, total play time = ~12 seconds, play position at ~24 seconds

    Lcd.SG2PauseWAVFile
    Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
    Lcd.SG2GetWAVPlayState(@state)
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Pause   "), @num_printed)  
    Delay.PauseSec(2)
    Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Pause   "), @num_printed)   
    Delay.PauseSec(2)
            
    ' Test pause/start command, check state, total play time = ~12 seconds, play position at ~24 seconds 

    Lcd.SG2PauseWAVFile
    Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
    Lcd.SG2GetWAVPlayState(@state)
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Running "), @num_printed)  
    Delay.PauseSec(2)
    Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Running "), @num_printed)   
    Delay.PauseSec(2)

    ' Test stop command, check state, total play time = ~16 seconds, play position at ~28 seconds
    
    Lcd.SG2StopWAVFile
    Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue
    Lcd.SG2GetWAVPlayState(@state)
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Stop    "), @num_printed)  
    Delay.PauseSec(2)
    Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
    if (state == 0)
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Inactive "), @num_printed) 
    else 
      Lcd.SG2DisplayString(0, 100, 239, 239, string("State = Active   "), @num_printed)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Play = Stop    "), @num_printed)   
    Delay.PauseSec(2)
    
    ' Total play time = ~16 seconds, play position at ~28 seconds   
      
  else
    Fmt.sprintf(@strbuf1, string("Song < %d Seconds!"), MinSongDuration)   
    Lcd.SG2DisplayString(0, 180, 239, 239, @strbuf1, @num_printed) 

  ' Update output and state fields
  
  Lcd.SG2SetAudioDacState(Lcd#AudioDacOff)
  Lcd.SG2SetTextFontColour($00, $00, $FF)  ' Blue  
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Output = Off "), @num_printed)
  Delay.PauseSec(2) 
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Output = Off "), @num_printed)
  Delay.PauseSec(1)   
  DisplaySetup(FALSE)
  
PRI TestGetTouchscreen | cur_x, cur_y, first_time, idle_start, index, prev_x, prev_y, num_printed, touch_status

  DisplayTestTitle(string("GetTouchscreen"), 0) 
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Touch anywhere to test"), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("Exits if idle >= 5 Secs"), @num_printed) 
  Delay.PauseSec(1)
  first_time := TRUE
  prev_x := 0
  prev_y := 0
  idle_start := cnt
  
  repeat
    touch_status := Lcd.SG2GetTouchscreen(@cur_x, @cur_y)
    if (touch_status)  ' Valid touch input occurred
      Fmt.sprintf(@strbuf1, string("%s"), string("Touch Input = VALID  "))
    else
      Fmt.sprintf(@strbuf1, string("%s"), string("Touch Input = NONE   "))
    index := Fmt.bprintf(@strbuf2, 0, string("(x, y) = %d, "), cur_x)
    index := Fmt.bprintf(@strbuf2, index, string("%d      "), cur_y)
    strbuf2[index] := 0   

    if (first_time OR ((cur_x <> prev_x) OR (cur_y <> prev_y)))
      first_time := FALSE
      Lcd.SG2DisplayString(0, 100, 239, 239, @strbuf1, @num_printed)
      Lcd.SG2DisplayString(0, 120, 239, 239, @strbuf2, @num_printed) 
    prev_x := cur_x
    prev_y := cur_y      
    if ((cur_x <> 0) OR (cur_y <> 0))
      idle_start := cnt
    Fmt.sprintf(@strbuf1, string("Idle time = %d Secs  "), (cnt - idle_start) / clkfreq)
    Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed) 
    if ((cnt - idle_start) => (5 * clkfreq))
      DisplaySetup(FALSE) 
      return
    Delay.PauseMSec(100)  
  
PRI TestGetTouchIcons | cur_icon, first_time, idle_start, prev_icon, num_printed
  
  DisplayTestTitle(string("GetTouchIcons"), 0) 
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Touch any icon to test"), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("Exits if idle >= 5 Secs"), @num_printed) 
  Delay.PauseSec(1)
  first_time := TRUE
  prev_icon := Lcd#TouchIconNone
  idle_start := cnt

  repeat
    Lcd.SG2GetTouchIcons(@cur_icon)
    case cur_icon
      Lcd#TouchIconNone:
        Fmt.sprintf(@strbuf1, string("%s"), string("Icon = NONE     "))
      Lcd#TouchIconHome:
        Fmt.sprintf(@strbuf1, string("%s"), string("Icon = HOME     "))
      Lcd#TouchIconMessage:                                
        Fmt.sprintf(@strbuf1, string("%s"), string("Icon = MESSAGE  "))
      Lcd#TouchIconBook:                                         
        Fmt.sprintf(@strbuf1, string("%s"), string("Icon = BOOK     "))
      Lcd#TouchIconPhone:                                 
        Fmt.sprintf(@strbuf1, string("%s"), string("Icon = PHONE    "))
      Lcd#TouchIconSong:
        Fmt.sprintf(@strbuf1, string("%s"), string("Icon = SONG     "))

    if (first_time OR (cur_icon <> prev_icon))
      first_time := FALSE
      Lcd.SG2DisplayString(0, 100, 239, 239, @strbuf1, @num_printed)
    prev_icon := cur_icon   
    if (cur_icon <> Lcd#TouchIconNone)
      idle_start := cnt
    Fmt.sprintf(@strbuf1, string("Idle time = %d Secs  "), (cnt - idle_start) / clkfreq)
    Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed) 
    if ((cnt - idle_start) => (5 * clkfreq))
      DisplaySetup(FALSE) 
      return
    Delay.PauseMSec(100)

PRI TestFatCommands | attributes, file_status, free_space, index, next_position, num_bytes_rw, num_dirs, num_files, num_printed, position, read_data, result_status, test_data, test_status, total_space, workspace_block_num, hour, minute, second, day, month, year

  workspace_block_num := 0 
  DisplayTestTitle(string("FatCommands"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green

  ' Test getting SD card stats.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Get SD card stats"), @num_printed)
  Lcd.SG2FatGetFreeTotalSpace(@free_space, @total_space, @file_status)
  Fmt.sprintf(@strbuf1, string("Free = %d KB"), free_space)   
  Lcd.SG2DisplayString(0, 60, 239, 239, @strbuf1, @num_printed)
  Fmt.sprintf(@strbuf1, string("Total = %d KB"), total_space) 
  Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 80, 239, 239, string("                        "), @num_printed)   

  ' Test opening a non-existent file.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Open non-existent file"), @num_printed)
  if (Lcd.SG2FatOpenFile(workspace_block_num, Lcd#FileOpenModeReadWrite, string("FatTestFile.dat"), @file_status))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
    Lcd.SG2FatCloseFile(workspace_block_num, @file_status)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test creating a new file.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Create new file"), @num_printed)
  if (Lcd.SG2FatNewFile(string("FatTestFile.dat"), @file_status))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test opening the new file.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Open new file"), @num_printed)
  if (Lcd.SG2FatOpenFile(workspace_block_num, Lcd#FileOpenModeReadWrite, string("FatTestFile.dat"), @file_status))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test writing/reading a file.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Write/read file"), @num_printed)
  repeat test_data from 0 to 10
    Lcd.SG2FatWriteFileLong(workspace_block_num, @test_data, @num_bytes_rw, @file_status)
  test_status := TRUE
  position := 0
  Lcd.SG2FatReadFileLongAtPos(workspace_block_num, @read_data, position, @num_bytes_rw, @file_status)
  if (read_data <> 0)
    test_status := FALSE  
  repeat test_data from 1 to 10      
    Lcd.SG2FatReadFileLong(workspace_block_num, @read_data, @num_bytes_rw, @file_status)
    if (read_data <> test_data)
      test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test saving a file.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Save file"), @num_printed)
  if (Lcd.SG2FatSaveFile(workspace_block_num, @file_status))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test set/get file pointer.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Set/Get File Pointer"), @num_printed)  
  next_position := 0
  position := 8
  read_data := 0
  test_status := TRUE 
  Lcd.SG2FatSetFilePointer(workspace_block_num, position, @file_status)
  Lcd.SG2FatReadFileLong(workspace_block_num, @read_data, @num_bytes_rw, @file_status)
  if (read_data <> 2)
    test_status := FALSE 
  Lcd.SG2FatGetFilePointer(workspace_block_num, @next_position, @file_status)
  if (next_position <> (position + 4))
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test File EOF/Error.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Test File EOF/Error"), @num_printed)
  position := 40
  read_data := 0
  result_status := 0
  test_status := TRUE  
  Lcd.SG2FatSetFilePointer(workspace_block_num, position, @file_status) 
  Lcd.SG2FatTestFileEOF(workspace_block_num, @result_status, @file_status)
  if (result_status <> $00)
    test_status := FALSE
  Lcd.SG2FatReadFileLong(workspace_block_num, @read_data, @num_bytes_rw, @file_status)
  if (read_data <> 10)
    test_status := FALSE
  Lcd.SG2FatTestFileEOF(workspace_block_num, @result_status, @file_status)
  if (result_status <> $01)
    test_status := FALSE
  Lcd.SG2FatTestFileError(workspace_block_num, @result_status, @file_status)
  if (result_status <> $00)
    test_status := FALSE
  if (file_status <> Lcd#FileStatusOk)
    test_status := FALSE  
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test truncating a file.
  
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Truncate File"), @num_printed)
  position := 8
  read_data := 0 
  result_status := 0
  test_status := TRUE  
  Lcd.SG2FatSetFilePointer(workspace_block_num, position, @file_status) 
  if (NOT Lcd.SG2FatTruncateFile(workspace_block_num, @file_status))
    test_status := FALSE
  position := 0
  Lcd.SG2FatSetFilePointer(workspace_block_num, position, @file_status)
  Lcd.SG2FatReadFileLong(workspace_block_num, @read_data, @num_bytes_rw, @file_status)
  if (read_data <> 0)
    test_status := FALSE
  Lcd.SG2FatReadFileLong(workspace_block_num, @read_data, @num_bytes_rw, @file_status)
  if (read_data <> 1)
    test_status := FALSE
  Lcd.SG2FatReadFileLong(workspace_block_num, @read_data, @num_bytes_rw, @file_status)
  Lcd.SG2FatTestFileEOF(workspace_block_num, @result_status, @file_status)
  if (result_status <> $01)
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test closing a file.
  
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Close file"), @num_printed)
  if (Lcd.SG2FatCloseFile(workspace_block_num, @file_status))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test renaming a file

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Rename file"), @num_printed)
  test_status := TRUE     
  if (NOT Lcd.SG2FatRenameOrMoveDirFile(string("FatTestFile.dat"), string("FatTestFileRenamed.dat"), @file_status))
    test_status := FALSE
  if (NOT Lcd.SG2FatOpenFile(workspace_block_num, Lcd#FileOpenModeReadWrite, string("FatTestFileRenamed.dat"), @file_status))
    test_status := FALSE     
  if (NOT Lcd.SG2FatCloseFile(workspace_block_num, @file_status))
    test_status := FALSE     
  if (NOT Lcd.SG2FatRenameOrMoveDirFile(string("FatTestFileRenamed.dat"), string("FatTestFile.dat"), @file_status))
    test_status := FALSE     
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test getting file size.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Get file size"), @num_printed)
  Lcd.SG2FatGetDirFileSize(string("FatTestFile.dat"), @total_space, @file_status)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("File = FatTestFile.dat"), @num_printed)
  Fmt.sprintf(@strbuf1, string("Size = %d Bytes"), total_space) 
  Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 80, 239, 239, string("                        "), @num_printed)

  ' Test setting/getting file time/date

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Set/Get file time/date"), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("File = FatTestFile.dat"), @num_printed)
  test_status := TRUE
  hour := 1
  minute := 22
  second := 31
  day := 13
  month := 1
  year := 2000
  if (NOT Lcd.SG2FatSetDirFileTimeDate(hour, minute, second, day, month, year, string("FatTestFile.dat"), @file_status))
    test_status := FALSE
  if (NOT Lcd.SG2FatGetDirFileTimeDate(string("FatTestFile.dat"), @hour, @minute, @second, @day, @month, @year, @file_status))
    test_status := FALSE
  index := Fmt.bprintf(@strbuf1, 0, string("Time = %d:"), hour)
  index := Fmt.bprintf(@strbuf1, index, string("%d:"), minute)
  index := Fmt.bprintf(@strbuf1, index, string("%d"), second)   
  strbuf1[index] := 0
  Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed)
  index := Fmt.bprintf(@strbuf1, 0, string("Date = %d/"), month)
  index := Fmt.bprintf(@strbuf1, index, string("%d/"), day)
  index := Fmt.bprintf(@strbuf1, index, string("%d"), year)   
  strbuf1[index] := 0
  Lcd.SG2DisplayString(0, 100, 239, 239, @strbuf1, @num_printed)
  ' For some reason the seconds field always gets set to 1 second less than requested.
  if ((hour <> 1) OR (minute <> 22) OR (second <> 30) OR (day <> 13) OR (month <> 1) OR (year <> 2000))
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 120, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 80, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 100, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 120, 239, 239, string("                        "), @num_printed)

  ' Test getting file FAT attributes

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Get file attributes"), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("File = FatTestFile.dat"), @num_printed) 
  Lcd.SG2FatGetDirFileAttribute(string("FatTestFile.dat"), @attributes, @file_status)
  index := Fmt.bprintf(@strbuf1, 0, string("A:D:V:S:H:R = %d:"), (attributes & Lcd#FatAttribArchive) >> 5)
  index := Fmt.bprintf(@strbuf1, index, string("%d:"), (attributes & Lcd#FatAttribDirectory) >> 4)
  index := Fmt.bprintf(@strbuf1, index, string("%d:"), (attributes & Lcd#FatAttribVolumeLabel) >> 3)
  index := Fmt.bprintf(@strbuf1, index, string("%d:"), (attributes & Lcd#FatAttribSystem) >> 2)
  index := Fmt.bprintf(@strbuf1, index, string("%d:"), (attributes & Lcd#FatAttribHiddenFile) >> 1)
  index := Fmt.bprintf(@strbuf1, index, string("%d"), (attributes & Lcd#FatAttribReadOnly))
  strbuf1[index] := 0
  Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 80, 239, 239, string("                        "), @num_printed)
    
  ' Test erasing a file.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Erase file"), @num_printed)   
  test_status := TRUE  
  if (Lcd.SG2FatEraseDirFile(string("FatTestFile.dat"), @file_status))
    if (Lcd.SG2FatOpenFile(workspace_block_num, Lcd#FileOpenModeReadWrite, string("FatTestFile.dat"), @file_status))
      test_status := FALSE
      Lcd.SG2FatCloseFile(workspace_block_num, @file_status) 
  else
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test creating a new directory.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Create new directory"), @num_printed)
  if (Lcd.SG2FatNewDir(string("FatTestDir"), @file_status))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test opening the new directory.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Open new directory"), @num_printed)
  if (Lcd.SG2FatOpenDir(string("FatTestDir"), @file_status))
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test getting the directory path

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Get directory path"), @num_printed)
  if (Lcd.SG2FatGetDirPath(@strbuf1, @file_status))
    Fmt.sprintf(@strbuf2, string("Path = %s"), @strbuf1)   
    Lcd.SG2DisplayString(0, 60, 239, 239, @strbuf2, @num_printed)
    if (strcomp(@strbuf1, string("0:/FatTestDir"))) 
      Lcd.SG2DisplayString(0, 80, 239, 239, string("Pass"), @num_printed)
    else
      Lcd.SG2DisplayString(0, 80, 239, 239, string("Fail"), @num_printed) 
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed) 
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 80, 239, 239, string("                        "), @num_printed)

  ' Create 2 test dirs and 2 test files. Get num dirs/files. Iterate through each dir/file item and compare to expected names.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Get dir/file names"), @num_printed)
  test_status := TRUE
  Lcd.SG2FatNewDir(string("FatTestDir1"), @file_status)
  Lcd.SG2FatNewDir(string("FatTestDir2"), @file_status)
  Lcd.SG2FatNewFile(string("FatTestFile1.dat"), @file_status)
  Lcd.SG2FatNewFile(string("FatTestFile2.dat"), @file_status)
  Lcd.SG2FatGetNumDirsFiles(@num_dirs, @num_files, @file_status)
  if ((num_dirs <> 2) OR (num_files <> 2))
    test_status := FALSE
  Fmt.sprintf(@strbuf1, string("Num dirs = %d"), num_dirs)   
  Lcd.SG2DisplayString(0, 60, 239, 239, @strbuf1, @num_printed)
  Fmt.sprintf(@strbuf1, string("Num files = %d"), num_files)   
  Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed)
  repeat index from 0 to (num_dirs - 1)
    Lcd.SG2FatGetDirName(index,  @strbuf1, @file_status)
    Fmt.sprintf(@strbuf2, string("Directory = %s"), @strbuf1)  
    Lcd.SG2DisplayString(0, 100, 239, 239, @strbuf2, @num_printed)
    Delay.PauseSec(1)
    Lcd.SG2DisplayString(0, 100, 239, 239, string("                        "), @num_printed)
    if (NOT (strcomp(@strbuf1, string("FatTestDir1")) OR strcomp(@strbuf1, string("FatTestDir2"))))
      test_status := FALSE
  repeat index from 0 to (num_files - 1)
    Lcd.SG2FatGetFileName(index,  @strbuf1, @file_status)
    Fmt.sprintf(@strbuf2, string("File = %s"), @strbuf1)
    Lcd.SG2DisplayString(0, 100, 239, 239, @strbuf2, @num_printed)
    Delay.PauseSec(1)
    Lcd.SG2DisplayString(0, 100, 239, 239, string("                        "), @num_printed)   
    if (NOT (strcomp(@strbuf1, string("FatTestFile1.dat")) OR strcomp(@strbuf1, string("FatTestFile2.dat"))))
      test_status := FALSE
  Lcd.SG2FatEraseDirFile(string("FatTestDir1"), @file_status)
  Lcd.SG2FatEraseDirFile(string("FatTestDir2"), @file_status)
  Lcd.SG2FatEraseDirFile(string("FatTestFile1.dat"), @file_status)
  Lcd.SG2FatEraseDirFile(string("FatTestFile2.dat"), @file_status)
  if (test_status)
    Lcd.SG2DisplayString(0, 100, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 100, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(1)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 80, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 100, 239, 239, string("                        "), @num_printed)  
  
  ' Move up to the root directory and erase the last test directory

  Lcd.SG2FatOpenDir(string(".."), @file_status)
  Lcd.SG2FatEraseDirFile(string("FatTestDir"), @file_status)  
  DisplaySetup(FALSE)

PRI TestRtcCommands | num_printed, result_status, test_status, hour, minute, second, day, month, year

  DisplayTestTitle(string("RtcCommands"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Initialize/setup clock"), @num_printed)
  test_status := TRUE 
  result_status := 0
  if (Lcd.SG2RtcSetup(@result_status))
    if (NOT result_status)
      test_status := FALSE
  else
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Set/get time/date"), @num_printed)
  test_status := TRUE
  hour := 1
  minute := 22
  second := 31
  day := 13
  month := 1
  year := 2000
  if (Lcd.SG2RtcSetTimeDate(hour, minute, second, day, month, year))
    if (Lcd.SG2RtcGetTimeDate(@hour, @minute, @second, @day, @month, @year))
      if ((hour <> 1) OR (minute <> 22) OR ((second <> 31) OR (second <> 32)) OR (day <> 13) OR (month <> 1) OR (year <> 2000))
        test_status := FALSE
    else
      test_status := FALSE
  else
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestEEPromFlashCommands | buffer_addr, index, num_bytes_rw, num_bytes_to_read, num_bytes_to_write, num_printed, page_num, result_status, test_status

  DisplayTestTitle(string("EEPromFlashCommands"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
    
  ' Test clearing the buffer.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Clear buffer"), @num_printed)
  buffer_addr := 0
  num_bytes_to_read := 100  
  test_status := TRUE  
  if (Lcd.SG2FlashClearBuffer)
    if (Lcd.SG2FlashReadBuffer(buffer_addr, num_bytes_to_read, @strbuf1, @num_bytes_rw))
      if (num_bytes_to_read == num_bytes_rw)
        repeat index from 0 to (num_bytes_to_read - 1)
          if (strbuf1[index] <> $FF)
            test_status := FALSE  
      else
        test_status := FALSE 
  else
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test writing/reading the buffer.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Write/read buffer"), @num_printed)
  buffer_addr := 0
  num_bytes_to_read := 100     
  num_bytes_to_write := 100  
  test_status := TRUE
  repeat index from 0 to (num_bytes_to_write - 1)
    strbuf1[index] := index
  if (Lcd.SG2FlashWriteBuffer(buffer_addr, num_bytes_to_write, @strbuf1, @num_bytes_rw))
    if (num_bytes_to_write == num_bytes_rw)
      if (Lcd.SG2FlashReadBuffer(buffer_addr, num_bytes_to_read, @strbuf2, @num_bytes_rw))
        if (num_bytes_to_read == num_bytes_rw)
          repeat index from 0 to (num_bytes_to_read - 1)
            if (strbuf2[index] <> index)
              test_status := FALSE  
        else
          test_status := FALSE 
    else
      test_status := FALSE
  else
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test erasing/comparing a page.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Erase/compare page"), @num_printed)
  page_num := 0        '
  result_status := 0
  test_status := TRUE  
  if (Lcd.SG2FlashErasePage(page_num))
    if (Lcd.SG2FlashClearBuffer)
      if (Lcd.SG2FlashCompareBufferToPage(page_num, @result_status))
        if (NOT result_status)
          test_status := FALSE     
      else
        test_status := FALSE
    else
      test_status := FALSE
  else
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)

  ' Test saving/filling page.

  Lcd.SG2DisplayString(0, 40, 239, 239, string("Save/fill page"), @num_printed)
  buffer_addr := 0
  num_bytes_to_read := 100     
  num_bytes_to_write := 100
  page_num := 0
  result_status := 0       
  test_status := TRUE
  repeat index from 0 to (num_bytes_to_write - 1)
    strbuf1[index] := index
  if (Lcd.SG2FlashWriteBuffer(buffer_addr, num_bytes_to_write, @strbuf1, @num_bytes_rw))
    if (Lcd.SG2FlashSaveBufferToPage(page_num))
      if (Lcd.SG2FlashClearBuffer)
        if (Lcd.SG2FlashFillBufferFromPage(page_num))
          if (Lcd.SG2FlashReadBuffer(buffer_addr, num_bytes_to_read, @strbuf2, @num_bytes_rw))
            repeat index from 0 to (num_bytes_to_read - 1)
              if (strbuf2[index] <> index)
                test_status := FALSE
          else
            test_status := FALSE
        else
          test_status := FALSE
      else
        test_status := FALSE 
    else
      test_status := FALSE
  else
    test_status := FALSE
  if (test_status)
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Pass"), @num_printed)
  else
    Lcd.SG2DisplayString(0, 60, 239, 239, string("Fail"), @num_printed)
  Delay.PauseSec(2)
  Lcd.SG2DisplayString(0, 40, 239, 239, string("                        "), @num_printed)
  Lcd.SG2DisplayString(0, 60, 239, 239, string("                        "), @num_printed)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestObjectCheckbox | num_printed
  
  DisplayTestTitle(string("ObjectCheckbox"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("State = Unchecked"), @num_printed)
  Lcd.SG2ObjectCheckbox(40, 80, 40, Lcd#ObjectStateInactive)
  Delay.PauseSec(1)

  DisplayTestTitle(string("ObjectCheckbox"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("State = Checked"), @num_printed)
  Lcd.SG2ObjectCheckbox(40, 80, 40, Lcd#ObjectStateActive)  
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestObjectButton | num_printed
  
  DisplayTestTitle(string("ObjectButton"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("State = Unselected"), @num_printed)
  Lcd.SG2ObjectButton(40, 80, 80, 120, Lcd#ObjectStateInactive, string("Test"))
  Delay.PauseSec(1)

  DisplayTestTitle(string("ObjectButton"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("State = Selected"), @num_printed)
  Lcd.SG2ObjectButton(40, 80, 80, 120, Lcd#ObjectStateActive, string("Test"))  
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestObjectSwitch | num_printed
  
  DisplayTestTitle(string("ObjectSwitch"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("State = Off"), @num_printed)
  Lcd.SG2ObjectSwitch(40, 80, 40, Lcd#ObjectStateInactive)
  Delay.PauseSec(1)

  DisplayTestTitle(string("ObjectSwitch"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("State = On"), @num_printed)
  Lcd.SG2ObjectSwitch(40, 80, 40, Lcd#ObjectStateActive)  
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestObjectProgressBar | num_printed, percent
  
  DisplayTestTitle(string("ObjectProgressBar"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  repeat percent from 0 to 100 step 25 
    Fmt.sprintf(@strbuf1, string("State = %d "), percent) 
    Lcd.SG2DisplayString(0, 40, 239, 239, @strbuf1, @num_printed)
    Lcd.SG2ObjectProgressBar(40, 80, 140, 120, percent)
    Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestObjectScrollBar | num_printed, active_state, bar_position, divisions, orientation

  divisions := 4
  repeat orientation from 0 to 1
    repeat active_state from 0 to 1
      repeat bar_position from 0 to (divisions - 1)
        DisplayTestTitle(string("ObjectScrollBar"), 0)
        Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
        if (orientation == 0)  
          Lcd.SG2DisplayString(0, 40, 239, 239, string("Dir = Horizontal "), @num_printed) 
        else
          Lcd.SG2DisplayString(0, 40, 239, 239, string("Dir = Vertical   "), @num_printed)
        if (active_state == 0)
          Lcd.SG2DisplayString(0, 60, 239, 239, string("State = Unselected "), @num_printed) 
        else
          Lcd.SG2DisplayString(0, 60, 239, 239, string("State = Selected   "), @num_printed)  
        Fmt.sprintf(@strbuf1, string("Position = %d "), bar_position) 
        Lcd.SG2DisplayString(0, 80, 239, 239, @strbuf1, @num_printed)
        if (orientation == 0)
          Lcd.SG2ObjectScrollBar(40, 120, 140, 160, bar_position, divisions, orientation, active_state) 
        else
          Lcd.SG2ObjectScrollBar(40, 120, 80, 220, bar_position, divisions, orientation, active_state) 
        Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestObjectSliderBar | num_printed, bar_position, divisions, orientation

  divisions := 4
  repeat orientation from 0 to 1
    repeat bar_position from 0 to (divisions - 1)
      DisplayTestTitle(string("ObjectSliderBar"), 0)
      Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
      if (orientation == 0)  
        Lcd.SG2DisplayString(0, 40, 239, 239, string("Dir = Horizontal "), @num_printed) 
      else
        Lcd.SG2DisplayString(0, 40, 239, 239, string("Dir = Vertical   "), @num_printed)
      Fmt.sprintf(@strbuf1, string("Position = %d "), bar_position) 
      Lcd.SG2DisplayString(0, 60, 239, 239, @strbuf1, @num_printed)
      if (orientation == 0)
        Lcd.SG2ObjectSliderBar(40, 100, 140, 140, bar_position, divisions, orientation) 
      else
        Lcd.SG2ObjectSliderBar(40, 100, 80, 200, bar_position, divisions, orientation) 
      Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestObjectWindow | num_printed, text_size

  text_size := 2  
  DisplayTestTitle(string("ObjectWindow"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Type = Unselected Clear"), @num_printed)
  Lcd.SG2ObjectWindow(40, 80, 200, 240, text_size, Lcd#ObjectWindowUnselectedTrans, string("Window"))
  Delay.PauseSec(1)

  DisplayTestTitle(string("ObjectWindow"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Type = Selected Clear"), @num_printed)
  Lcd.SG2ObjectWindow(40, 80, 200, 240, text_size, Lcd#ObjectWindowSelectedTrans, string("Window"))  
  Delay.PauseSec(1)

  DisplayTestTitle(string("ObjectWindow"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Type = Selected Gray"), @num_printed)
  Lcd.SG2ObjectWindow(40, 80, 200, 240, text_size, Lcd#ObjectWindowSelectedGray, string("Window"))  
  Delay.PauseSec(1)
 
  DisplayTestTitle(string("ObjectWindow"), 0)
  Lcd.SG2SetTextFontColour($00, $FF, $00)  ' Green
  Lcd.SG2DisplayString(0, 40, 239, 239, string("Type = Selected White"), @num_printed)
  Lcd.SG2ObjectWindow(40, 80, 200, 240, text_size, Lcd#ObjectWindowSelectedWhite, string("Window"))  
  Delay.PauseSec(1)
  DisplaySetup(FALSE)
    
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}