{
''***************************************
''*  MAX675 v1.1                        *
''*  Author: Mike Lord                  *
''*  Copyright (c) Mike Lord            *
''*  Mike@electronicdesignservice.com   *
''*  650-219-6467                       *                
''*  See end of file for terms of use.  *               
''***************************************

' v1.0 - 01 Jul7 2011 - original version

This is written as a spin driver for the max6675 K type thermocouple chip.


┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ MAX6675 driver                      │ PG             | (C) 2011            | July 20 2011  |
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ A driver for the MAX6675 K Type theromcouple chip                                          │
|                                                                                            |   
| See end of file for terms of use                                                           |
└────────────────────────────────────────────────────────────────────────────────────────────┘
 SCHEMATIC
                      ┌────┐      
             Gnd 1  │      │ 8 Nc    
             T+  2  │MAX   │ 7 Sd
             T-  3  │6675  │ 6 Cs
             Vcc 4  │      │ 5 Sck
                      └──────┘      



 }
CON

   
Var


obj

      Tv        :  "Mirror_TV_Text"
 

'==================================================================
Pub  ReadTemp(SD, CS, SCK, TempScale , TempertureIn_Addr )  | Index  , AddrVar
'==================================================================
              ' SD, CS, SCK are the pin numbers of the propeller connected to the max6675
              'TempScale  = 1     '1 is Farienheight   0 is Centegrade  
              
           dira[Cs] := 1
           dira[SCK] := 1
           dira[Sd] := 0 

          
          Outa[Cs] := 1     'Make sure chip select is high
          Outa[SCK] := 0    'make sure Sck is low as initial value
          
          Outa[Cs] := 0     'Now take Chip select low to shart shift out of data

          Tv.out($0A)      'X position follows
          Tv.out( 1 + index )
          Tv.out($0B)      'Y position follows
          Tv.out( 3 )



          'Repeat Index from 0 to 15
                Waitcnt(clkfreq /10_000 + cnt)
                Outa[SCK] := 1
                Waitcnt(clkfreq /10_000 + cnt)
                Outa[SCK] := 0      'Data is now ready to be read
                
                Long[@TempertureIn_Addr] :=  67   'Ina[Sd]

                Tv.hex( @TempertureIn_Addr, 4 )                  
                Tv.Str(String("-")) 
                Tv.dec(Long[@TempertureIn_Addr])
                Tv.Str(String("  "))      

                
     Outa[Cs]  := 1     'Make sure chip select is high
     Outa[SCK] := 0    'make sure Sck is low as initial value

           '  Tv.out($0D)
        'Tv.Str(String("after routine")) 

  return

{
  
PUB SHIFTIN (Dpin, Cpin, Mode, Bits) : Value | InBit
{{
   Shift data in, master clock, for mode use BS2#MSBPRE, #MSBPOST, #LSBPRE, #LSBPOST
   Clock rate is ~16Kbps.  Use at 80MHz only is recommended.
     X := BS2.SHIFTIN(5,6,BS2#MSBPOST,8)
}}
    dira[Dpin]~                                            ' Set data pin to input
    outa[Cpin]:=0                                          ' Set clock low 
    dira[Cpin]~~                                           ' Set clock pin to output 
                                                
    If Mode == MSBPRE                                      ' Mode - MSB, before clock
       Value:=0
       REPEAT Bits                                         ' for number of bits
          InBit:= ina[Dpin]                                ' get bit value
          Value := (Value << 1) + InBit                    ' Add to  value shifted by position
          !outa[Cpin]                                      ' cycle clock
          !outa[Cpin]
          waitcnt(1000 + cnt)                              ' time delay

    elseif Mode == MSBPOST                                 ' Mode - MSB, after clock              
       Value:=0                                                          
       REPEAT Bits                                         ' for number of bits                    
          !outa[Cpin]                                      ' cycle clock                         
          !outa[Cpin]                                         
          InBit:= ina[Dpin]                                ' get bit value                          
          Value := (Value << 1) + InBit                    ' Add to  value shifted by position                                         
          waitcnt(1000 + cnt)                              ' time delay                            
                                                                 
    elseif Mode == LSBPOST                                 ' Mode - LSB, after clock                    
       Value:=0                                                                                         
       REPEAT Bits                                         ' for number of bits                         
          !outa[Cpin]                                      ' cycle clock                          
          !outa[Cpin]                                                                             
          InBit:= ina[Dpin]                                ' get bit value                        
          Value := (InBit << (bits-1)) + (Value >> 1)      ' Add to  value shifted by position    
          waitcnt(1000 + cnt)                              ' time delay                           

    elseif Mode == LSBPRE                                  ' Mode - LSB, before clock             
       Value:=0                                                                                   
       REPEAT Bits                                         ' for number of bits                   
          InBit:= ina[Dpin]                                ' get bit value                        
          Value := (Value >> 1) + (InBit << (bits-1))      ' Add to  value shifted by position    
          !outa[Cpin]                                      ' cycle clock                          
          !outa[Cpin]                                                                             
          waitcnt(1000 + cnt)                              ' time delay

    elseif Mode == OnClock                                            
       Value:=0
       REPEAT Bits                                         ' for number of bits
                                        
          !outa[Cpin]                                      ' cycle clock
          waitcnt(500 + cnt)                               ' get bit value
          InBit:= ina[Dpin]                               ' time delay
          Value := (Value << 1) + InBit                    ' Add to  value shifted by position
          !outa[Cpin]
          waitcnt(500 + cnt)                           
     

 }
  

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