{{
┌────────────────────────────────┬───────────────────────┬─────────────────────────────────────┬─────────────────┐
│ ID v1.0                        │ by Matthew Cornelisse │ Copyright (c) 2009 VisiblePhoto.com │ 20 January 2009 │
├────────────────────────────────┴───────────────────────┴─────────────────────────────────────┴─────────────────┤
│                                                                                                                │
│ This object generates a 256 bit random id number and stores it in the eeprom so future boots have the same     │
│ number.                                                                                                        │
│                                                                                                                │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

Con
  MemoryLocation = $7FE0        'Location in memory to store ID.  $7FE0 will place at end of eeprom

OBJ
  i2c : "Basic_I2C_Driver"
  oRR : "RealRandom"
  
PUB initialize | x
  ''Run at begining of program.  Will generate a 256bit id number if not already present  
  if Long[MemoryLocation]|Long[MemoryLocation+4]==0
    oRR.start
    repeat x from 0 to 7
      Long[MemoryLocation+x*4]:=oRR.random
    oRR.stop
    return i2c.WritePage(i2c#BootPin, i2c#EEPROM, MemoryLocation, MemoryLocation, 32)
  else
    return 0

PUB idNum(x)
  ''returns 1 of 8 longs representing the randomly assinged id number
  ''x=0 to 7
  return Long[MemoryLocation+x*4]

PUB idNumLocation
  ''returns memory location of ID Number
  return MemoryLocation

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