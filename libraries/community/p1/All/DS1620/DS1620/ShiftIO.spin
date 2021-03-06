'' *****************************
'' *  ShiftIO                  *
'' *  (C) 2006 Parallax, Inc.  *
'' *****************************
''
'' Mimics SHIFTOUT and SHIFTIN functions of the BS2.  For flexibility,
'' the clock pin is toggled so the user must preset the clock line to
'' the idle state:
''
''
'' data    
'' clock0  
'' clock1  


CON

  #0, LsbFirst, MsbFirst                                ' shiftout modes
  #0, MsbPre, LsbPre, MsbPost, LsbPost                  ' shiftin modes
  

OBJ

  delay : "timing"

  
PUB shiftout(dpin, cpin, mode, value, bits)

  dira[dpin]~~                                          ' make pins outputs
  dira[cpin]~~

  case mode
  
    LsbFirst:
      value <-= 1                                       ' pre-align lsb
      repeat bits
        outa[dpin] := (value ->= 1) & 1                 ' output data bit
        delay.pause10us(1)                              ' let it settle
        !outa[cpin]                                     ' clock the bit
        delay.pause10us(1)
        !outa[cpin]

    MsbFirst:
      value <<= (32 - bits)                             ' pre-align msb
      repeat bits
        outa[dpin] := (value <-= 1) & 1                 ' output data bit
        delay.pause10us(1)                              ' let it settle
        !outa[cpin]                                     ' clock the bit
        delay.pause10us(1)
        !outa[cpin]


PUB shiftoutstr(dpin, cpin, mode, str_addr, count)

  repeat count
    shiftout(dpin, cpin, mode, byte[str_addr++], 8)


PUB shiftin(dpin, cpin, mode, bits) | value

  dira[dpin]~                                           ' make dpin input
  dira[cpin]~~                                          ' make cpin output
  value~                                                ' clear output 

  case mode

    MsbPre:
      repeat bits
        value := (value << 1) | ina[dpin]
        !outa[cpin]                                             ' 
        delay.pause10us(1)
        !outa[cpin]
        delay.pause10us(1) 

    LsbPre:
      repeat bits
        value := (value >> 1) | (ina[dpin] << 31)
        !outa[cpin]                                             ' 
        delay.pause10us(1)
        !outa[cpin]
        delay.pause10us(1)
      value >>= (32 - bits)

    MsbPost:
      repeat bits
        !outa[cpin]                                             ' 
        delay.pause10us(1)
        value := (value << 1) | ina[dpin]
        !outa[cpin]                                             ' 
        delay.pause10us(1)        
    
    LsbPost:
      repeat bits
        !outa[cpin]                                             ' 
        delay.pause10us(1)
        value := (value >> 1) | (ina[dpin] << 31) 
        !outa[cpin]
        delay.pause10us(1)
      value >>= (32 - bits)

  return value  
