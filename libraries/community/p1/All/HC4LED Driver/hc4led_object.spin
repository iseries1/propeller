con
ascii = 1
binary = 2
{{

┌──────────────────────────────────────────┐
│ HC4LED Driver                            │
│ Author: Thomas Watson                    │               
│ Copyright (c) 2008 Thomas Watson         │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘



This is an object that drives the HC4LED 7 segment LED display modules from Hitt Consulting.
It has a fair amount of capabilities and ways of driving the display.

Revision History

  8/25/08  v1.1  Fixed a bug in dispsegments where I forgot to release the direction pins and added the MIT license.

  8/24/08  v1.0  Initial Release

Data Format
The display uses 8 bits for each character, even though the first bit is ignored.
It is impossible to drive the decimal points because of the limititations of the controller.
This is the format for a long of data to be written to the display

%<rightmost digit>_<right digit>_<left digit>_<leftmost digit>

Each byte has the following format

%<zero>_<segment bits>
The segment bits are ordered like this
    
  ----5----
 |         |
 |         |
 6         4
 |         |
 |         |
 |----7----|
 |         |
 |         |
 1         3
 |         |
 |         |
  ----2----

Therefore, %00111101 would produce a 3 on the corresponding digit on the display.


Data Timing/Protocol

The display uses a synchronous serial protocol to transmit data.
Data gets transferred on the rising edge of the clock (0 to 1).
After all 32 bits are transferred, the clock must be left high for at least 1 millisecond for the display to update.

This is a probably bad timing diagram of transfers.

         MSB                                                          LSB
          │                                                            │
                                                                      
Data                                   

          
Clock    



Display Hookup

This assumes you are looking at the front of the display, with the cable facing up.
You MUST hook Blank to ground, or the display will not show anything!!!!

+5V     ─────────────────────────────────┐
Gnd     ───────────────────────────────┐ │
Blank   ─────────────────────────────┐ │ │
N/C      ───────────────────────────┐ │ │ │
Clock   ─────────────────────────┐ │ │ │ │
Data    ───────────────────────┐ │ │ │ │ │
                                │ │ │ │ │ │
          ┌─────────────────────┴─┴─┴─┴─┴─┴─────────────────────┐
          │  ┌───────────────────────────────────┐         ┌──┐ │                    
          │  │                                   │         │  │ │
          │  │                                   │         │  │ │
          │  │                                   │         │  │ │
          │  │                                   │         │  │ │
          │  │                                   │         │  │ │
          │  └───────────────────────────────────┘         └──┘ │
          └─────────────────────────────────────────────────────┘
          
}}
                                                                                      

var
byte cogs[4], count, status[4]
long stk[25*4]

pub scroll(m1, m2, clkpin, datpin, textaddr, repeatnum, len, delay)
if m1 == binary
  cogs[count] := cognew(binscroll(m2, clkpin, datpin, textaddr, repeatnum, len, delay, count), @stk+(count*25)) + 1
elseif m1 == ascii
  cogs[count] := cognew(asciiscroll(m2, clkpin, datpin, textaddr, repeatnum, delay, count), @stk+(count*25)) + 1
count++
waitcnt(clkfreq/10000+cnt)
return count - 1

pub disptext(clkpin, datpin, textaddr)
dira[clkpin] := 1
dira[datpin] := 1
disp(clkpin, datpin, charlookup[byte[textaddr]] | charlookup[byte[textaddr+1]] << 8 | charlookup[byte[textaddr+2]] << 16 | charlookup[byte[textaddr+3]] << 24)
dira[clkpin] := 0
dira[datpin] := 0

pub dispnum(clkpin, datpin, num, zeros) | temp, n1, n2, n3, n4
dira[clkpin] := 1
temp := false
dira[datpin] := 1
n4 := num
n3 := num                    
n2 := num
n1 := num
if zeros
  n1 /= 1000
  n2 /= 100
  n2 -= (n1*10)
  n3 /= 10                      
  n3 -= (n1*100) + (n2*10)
  n4 -= (n1*1000) + (n2*100) + (n3*10)
else
  n1 /= 1000
  n2 /= 100
  n2 -= (n1*10)
  n3 /= 10                      
  n3 -= (n1*100) + (n2*10)
  n4 -= (n1*1000) + (n2*100) + (n3*10)
  if n1 <> 0
    temp := true
    n1 += "0"
  else
    n1 := " "
  if n2 == 0 and not temp
    n2 := " "
  else
    temp := true
    n2 += "0"
  if n3 == 0 and not temp
    n3 := " "
  else
    temp := true
    n3 += "0"
  if n4 == 0 and not temp
    n4 := " "
  else
    temp := true
    n4 += "0"
if zeros  
  n4 += "0"
  n3 += "0"
  n2 += "0"
  n1 += "0"
disp(clkpin, datpin, charlookup[n1] | charlookup[n2] << 8 | charlookup[n3] << 16 | charlookup[n4] << 24)
dira[clkpin] := 0
dira[datpin] := 0

pub dispsegments(clkpin, datpin, d1, d2, d3, d4)
dira[clkpin] := 1
dira[datpin] := 1
disp(clkpin, datpin, d1 | d2 << 8 | d3 << 16 | d4 << 24)
dira[clkpin] := 0
dira[datpin] := 0

pub isDone(id) 
return status[id] == false

pub stop
if cogs[--count]
  cogstop(cogs[count]~ - 1)
else
  count++

pri disp(clkpin, datpin, data)
repeat 32
  outa[datpin] := data >> 31
  outa[clkpin] := 0
  waitcnt(clkfreq/20000+cnt)
  outa[clkpin] := 1
  waitcnt(clkfreq/20000+cnt)
  data <<= 1
waitcnt(clkfreq/900+cnt)  

pri binscroll(m2, clkpin, datpin, textaddr, repeatnum, len, delay, id) | numrepeated, i
status[id] := true
numrepeated := 0
dira[clkpin] := 1
dira[datpin] := 1
repeat
  repeat i from 0 to len - 4
    disp(clkpin, datpin, byte[textaddr+i] | byte[textaddr+(i+1)] << 8| byte[textaddr+(i+2)] << 16 | byte[textaddr+(i+3)] << 24)
    if m2 == 2
      if i <> strsize(textaddr) - 4
        waitcnt(delay+cnt)
    else
      waitcnt(delay+cnt)
  if numrepeated < 0
  else
    numrepeated++
    if numrepeated == repeatnum
      quit
status[id] := false
count--
dira[clkpin] := 0
dira[datpin] := 0

pri asciiscroll(m2, clkpin, datpin, textaddr, repeatnum, delay, id) | numrepeated, i
status[id] := true
numrepeated := 0
dira[clkpin] := 1
dira[datpin] := 1
repeat
  repeat i from 0 to strsize(textaddr) - 4
    disp(clkpin, datpin, charlookup[byte[textaddr+i]] | charlookup[byte[textaddr+(i+1)]] << 8 | charlookup[byte[textaddr+(i+2)]] << 16 | charlookup[byte[textaddr+(i+3)]] << 24)
    if m2 == 2
      if i <> strsize(textaddr) - 4
        waitcnt(delay+cnt)
    else
      waitcnt(delay+cnt)
  if repeatnum < 0
  else
    numrepeated++
    if numrepeated == repeatnum
      quit
status[id] := false
count--
dira[clkpin] := 0
dira[datpin] := 0

dat
charlookup
byte %01001000[32] 'first 32 control characters
byte 0             'space
byte %01001000[15] 'special symbols for things like percentage
'numbers start
byte %01111110
byte %01000010
byte %01101101
byte %00111101
byte %00011011
byte %00110111
byte %01110011
byte %00011100
byte %01111111
byte %00011111
'numbers end
byte %01001000[7] 'other special symbols
'start of uppercase letters
byte %01011111
byte %01110011
byte %01100001
byte %01111001
byte %01100111
byte %01000111
byte %00111111
byte %01011011
byte %00010000
byte %01111000
byte %01010111
byte %01100010
byte %01010101
byte %01010001
byte %01110001
byte %01001111
byte %00011111
byte %01000001
byte %00110111
byte %01100011
byte %01110000
byte %00101010
byte %01110100
byte %01011011
byte %00111011
byte %01001001
'end of uppercase letters
byte %01001000[6] 'more special characters
'start of lowercase letters
byte %01011111
byte %01110011
byte %01100001
byte %01111001
byte %01100111
byte %01000111
byte %00111111
byte %01011011
byte %00010000
byte %01111000
byte %01010111
byte %01100010
byte %01010101
byte %01010001
byte %01110001
byte %01001111
byte %00011111
byte %01000001
byte %00110111
byte %01100011
byte %01110000
byte %00101010
byte %01110100
byte %01011011
byte %00111011
byte %01001001
'end of lowercase letters    

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

