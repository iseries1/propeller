
{{

  ┌──────────────────────────────────────────┐
  │ led_pwm v1.0                             │
  │ Author: Colin Fox <greenenergy@gmail.com>│
  │ Copyright (c) 2011 Colin Fox             │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘

  Thanks to David Galloway for code review, suggestions and debugging help.

  This driver will drive up to 32 LEDs at 64 different brightness levels. It supports
  an optional automated decay feature, which is useful for animated displays such as chaser
  lights. You supply a longword structure with 3 parameters followed by the array of LED
  values. The 3 parameters are respectively: number of LEDs, the first LED pin #, and the
  persistence value. A persistence value of 0 disables the automatic decay feature.


  Usage example:

  ' -----------------------------

_xinfreq = 5_000_000
_clkmode = xtal1 + pll16x

CON
  _numleds = 8

VAR
  long numleds_, firstled_, persistence_, leds[_numleds]    'these must appear in this order

OBJ
  led          : "led_pwm"

PUB Main | x
  numleds_ := _numleds
  firstled_ := 16
  persistence_ := 0    ' set to 0 to disable decay

  led.start(@numleds_)

  repeat x from 0 to _numleds-1
     leds[x] := x*8

 waitcnt((clkfreq * 5) + cnt)

 led.stop
  ' -----------------------------

        The basic algorithm is to break the PWM wave up into 64 parts, and enable or disable each LED
        based on which part we're on, and what the current LED value is.

        With a delay wait value of 1000,
        which at 80 MHz is 1/80000 of a second. Since we are using 64 wave segments, this means an effective
        pwm frequency of 1.25 kHz. An LED at a brightness of 1 will be lit for 1/64 of that, which is about
        1/19 of a second, so if you move it quickly you could see some strobing, but at most brightness levels
        the strobing is almost imperceptible.

        At a delay of 600, the effective PWM frequency is 2.083 kHz, and a level 1 brightness LED is strobing at
        32 Hz.

        Changes:  v1.0          Initial release

}}

VAR
  long  cog

PUB start(ledptr)

  cog := cognew(@entry, ledptr) +1

PUB stop

  if cog
    cogstop(cog~ -1 )

DAT
        ORG   0
entry
              mov             ledbase, par

              rdlong          numleds, ledbase
              add             ledbase, #4
              rdlong          ledpin, ledbase
              add             ledbase, #4
              rdlong          decayrs, ledbase
              add             ledbase, #4

              ' Now build the output register mask
              mov             pins, #1
              shr             pins, #1         wc ' set the carry
              rcl             pins, numleds       ' set the low (numleds) bits
              shl             pins, ledpin        ' shift the mask into position
              mov             dira, pins

              mov             time, cnt                 ' Take the current time
              add             time, delay               ' And give ourselves time for setup

:mainloop     mov             decaycount, decayrs

:decayloop    mov             wavepart, wavemax

:waveloop     mov             index, ledbase
              mov             accum, #0
              mov             counter, numleds               ' counter = number of LEDs

:ledloop      rdlong          ledval, index
              shl             accum, #1

              ' for
              '    cmp value1,value2
              '      if the wz flag is set, z is set if value1 = value2
              '      if the wc flag is set, c is set if value1 < value2

              cmp             wavepart, ledval   wc, wz
 if_c_or_z    or              accum, #1
              add             index, #4
              djnz            counter, #:ledloop

              shl             accum, ledpin

              waitcnt         time, delay

              mov             outa, accum
              djnz            wavepart, #:waveloop

              djnz            decaycount, #:decayloop

              cmp             decayrs, #0  wz                                   ' Check to see if the user wanted decay
      if_z    jmp             #:mainloop

              mov             decaycount, decayrs
              mov             index, ledbase
              mov             counter, numleds

              ' Now loop through the LEDs and for each one, if the value >= 1, subtract 1
              ' (this is the cmpsub instruction). This reduces the LEDs towards zero without
              ' risking overshooting into negatives.

:loop2        rdlong          ledval, index
              cmpsub          ledval, #1
              wrlong          ledval, index
              add             index,  #4
              djnz            counter,#:loop2

              jmp             #:mainloop

delay   long  600   ' Actual PWM carrier, period will be delay * wavemax
wavemax long  64     ' number of pwm sub-segments

' Make sure res elements always come last
pins       res   1
decayrs    res   1    ' the number of full waves to output before decaying one step
wavepart   res   1    ' the current pwm wave value
decaycount res   1    ' the current decay value
index      res   1    ' which LED we're working on
ledval     res   1    ' current value of the LED
counter    res   1    ' ordinal of LED we're working on
time       res   1
accum      res   1    ' accumulator, to be sent to outa
ledbase    res   1    ' the first LED location in hub ram
numleds    res   1
ledpin     res   1    ' which pin is the first LED
              FIT

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

