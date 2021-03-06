{{
┌───────────────────────────────┬───────────────────┬────────────────────┐   
│  GPS_Str_NMEA_Lite.spin v1.0  │ Author: I.Kövesdi │ Rel.: 24. jan 2009 │  
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │ 
│  The 'GPS_Str_NMEA_Lite' driver interfaces the Propeller to a GPS      │
│ receiver. This NMEA-0183 parser captures and decodes RMC and GGA type  │
│ sentences of the GPS Talker device in a robust way.                    │ 
│                                                                        │  
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The NMEA-0813 standard for interfacing marine electronics devices     │
│ specifies the NMEA data sentence structure also general definitions    │
│ of approved sentences. However, the specification does not cover       │
│ implementation and design.                                             │
│  NMEA data is sent from one Talker to Listeners in 8-bit ASCII where   │
│ the MSB is set to zero. The specification also has a set of reserved   │
│ characters. These characters assist in the formatting of the NMEA data │
│ string. The specification also states valid characters and gives a     │
│ table of these characters ranging from HEX 20 to HEX 7E.               │
│  Most GPS unit acts as an NMEA 'Talker'device and sends navigation and │
│ satellite information via an RS232 or TTL serial interface using NMEA  │
│ sentence format starting with '$GP' where '$' is the start of message  │
│ character and 'GP' is the Talker identifier (for GPS). The next 3 ASCII│
│ characters, like 'RMC' in the '$GPRMC' sentence header, define the     │
│ sentence identifier.                                                   │
│  All units that support NMEA should support 4_800 baud (bit per second)│
│ rate. Most NMEA Talker devices can transmit NMEA data at higher baud   │
│ rates, as well. This driver that makes the Prop as a Listener, was     │
│ tested and was found to work well at 4_800 baud and at several higher  │
│ baud rates up to 115_200.                                              │
│  This driver recognizes the NMEA sentences of a GPS Talker device and  │
│ extracts the navigation information from the RMC, GGA, GLL ones and    │
│ the satellite information from the GSV and GSA sentences. Each of these│
│ sentences ends with a <CR> <LF> sequence (HEX 0D, 0A) and can be no    │
│ longer than 79 characters of visible text (plus start of message '$'   │
│ and line terminators <CR><LF>).                                        │
│  The data is contained within a single line with data items separated  │
│ by commas. The minimum number of data fields is 1. The data itself is  │
│ just ASCII text and may extend over multiple sentences in certain      │
│ specialized instance (e.g. GSV sentence packet) but is normally fully  │
│ contained in one variable length sentence. The data may vary for       │
│ precision contained in the message. For example time might be indicated│
│ to decimal parts of a second or location may be show with 3 or even 4  │
│ digits after the decimal point. The driver uses the commas to find     │
│ field boundaries and this way it can accept all precision variants.    │
│  There is a  checksum at the end of each listened sentence that is     │
│ verified by the driver. The checksum field consists of a '*' and two   │
│ hex digits representing an 8 bit exclusive OR of all characters        │
│ between, but not including, the '$' and '*'.                           │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  This driver has the "GPS_Str_NMEA.spin v1.0" Driver as its heavy      │
│ sibling,but with much more features.                                   │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_CLKMODE        = XTAL1 + PLL16X
_XINFREQ        = 5_000_000

'NMEA sentences ends with <CR>, <LF> (13, 10) bytes. I used only <CR> 
'here to detect sentence termination
_CR             = 13        'Carriage Return ASCII character

_MAX_NMEA_SIZE  = 82        'Including '$', <CR>, <LF> (NMEA-183 protocol)                            

_MAX_FIELDS     = 20        '(NMEA-183 protocol) 

'-----------------Recommended Minimum Specific GNSS Data------------------     
_RMC            = 1         'Time, date, position, course and speed data
                            
'------------------Global Positioning System Fixed Data------------------- 
_GGA            = 2         'Time, position, altitude, MSL and fix data
                            

VAR

LONG nmea_Rx_Stack[50]
LONG nmea_D_Stack[50]


'COG identifiers
BYTE cog1, cog2, cog3 

BYTE semID_Refresh        'Semaphore ID for allow/deny external data acces
                          'Lock with this ID is set (RED) : data not ready
                          '            If cleared (GREEN) : data ready
BYTE semID_BlockMove      'Semaphore ID for allow / deny strBuffer block
                          'moves                                      

'Arrays used in NMEA sentence receiving / processing
LONG cptr, cptr1, cptr2
BYTE strBufferRx[_MAX_NMEA_SIZE]
BYTE strBuffer1[_MAX_NMEA_SIZE]
BYTE strBuffer2[_MAX_NMEA_SIZE]      
WORD fieldPtrs[_MAX_FIELDS]         

LONG lastReceived        'Type of last received NMEA sentence
LONG ptrNMEASentType     'Pointer to last recognised NMEA sentence type
LONG ptrNMEANotRecog     'Pointer to last not recognised NMEA sent. type

LONG nmeaCntr0           'NMEA started sentence counter
LONG nmeaCntr1           'NMEA verified sentence counter
LONG nmeaCntr2           'NMEA failed sentence counter
LONG rmcCntr
LONG ggaCntr
LONG gllCntr
LONG gsvCntr
LONG gsaCntr

LONG ccCks
LONG rXCks


OBJ

GPS_UART :  "FullDuplexSerial"               'With 16 byte buffer
                                             'Can be used here up to
                                             '57_600 baud. At higher baud
                                             'rates use the 'Extended'
                                             'variant with 256 byte buffer 
                                              
'GPS_UART :  "FullDuplexSerialExtended"       'With 256 byte buffer

   
  
PUB StartCOGs(rX_FR_GPS,tX_TO_GPS,nmea_Mode,nmea_Baud) : oKay
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ StartCOGs │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: -Starts FullDuplexSerial (that will launch a COG)
''             -Starts 2 COGs for two  SPIN inerpreters for the
''             Concurent_NMEA_Receiver and Concurent_NMEA_Decoder
''             procedures
''             -Resets global pointers                                 
'' Parameters: Rx, Tx pins on Prop and mode, baud parameters for the
''             serial communication with the GPS                                 
''    Results: TRUE if successful, FALSE otherwise                                                                
''+Reads/Uses: cog1, cog2, cog3                                               
''    +Writes: None                                    
''      Calls: None                                                                  
'-------------------------------------------------------------------------
  
'Start FullDuplexSerial for GPS NMEA communication. This will be used
'exclusively by the "Concurent_NMEA_Receiver" procedure
cog1 := GPS_UART.Start(rX_FR_GPS,tX_TO_GPS,nmea_Mode,nmea_Baud)

'Start a SPIN interpreter in separate COG to execute the tokens of the
'"Concurent_NMEA_Receiver" SPIN procedure parallely with the other COGs
cog2 := COGNEW(Concurent_NMEA_Receiver, @nmea_Rx_Stack) + 1

'Start a SPIN interpreter in separate COG to execute the tokens of the
'"Concurent_NMEA_Decoder" SPIN procedure parallely with the other COGs
cog3 := COGNEW(Concurent_NMEA_Decoder, @nmea_D_Stack) + 1 

oKay := cog1 AND cog2 AND cog3
'If oKay then the necessary 3 COGS were available

IF oKay
  'Allow some time for the Concurent_NMEA_Receiver process to fill up the
  'data string table
  WAITCNT(2 * CLKFREQ + CNT)
ELSE    'Some COG was not available
  IF cog1
    GPS_UART.Stop
  IF cog2
    COGSTOP(cog2 - 1)
  IF cog3
    COGSTOP(cog3 - 1)
     
'Reset global pointers
cptr~
cptr1~
cptr2~    
      
RETURN oKay


PUB StopCOGs
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ StopCOGs │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Stops recruited COGs                                 
'' Parameters: None                                 
''    Results: None                                                                
''+Reads/Uses: cog1, cog2                                               
''    +Writes: None                                    
''      Calls: None                                                                  
'-------------------------------------------------------------------------  

GPS_UART.Stop                  'This stops cog1
COGSTOP(cog2 - 1)
COGSTOP(cog3 - 1)
'-------------------------------------------------------------------------




  
PUB Str_UTC_Time
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Str_UTC_Time │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns the UTC data string                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strTime
'-------------------------------------------------------------------------


PUB Str_UTC_Date
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐--------------------------
'------------------------------│ Str_UTC_Date │--------------------------
'------------------------------└──────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the UTC date string                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                    
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strDate       
'-------------------------------------------------------------------------


PUB Str_Latitude
'-------------------------------------------------------------------------
'-------------------------------┌──────────────┐--------------------------
'-------------------------------│ Str_Latitude │--------------------------
'-------------------------------└──────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Latitude data string     
'' Parameters: None                                 
''    Results: Pointer to string                                                   
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLatitude      
'-------------------------------------------------------------------------


PUB Str_Lat_N_S
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Str_Lat_N_S │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns hemisphere for the Latitude data (N, S)
'' Parameters: None                                 
''    Results: Pointer to string                                                   
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLat_N_S 
'-------------------------------------------------------------------------

    
PUB Str_Longitude
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ Str_Longitude │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Longitude data string    
'' Parameters: None                                 
''    Results: Pointer to string                                                   
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLongitude
'-------------------------------------------------------------------------
        

PUB Str_Lon_E_W
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Str_Lon_E_W │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Hemisphere for Longitude (E, W)
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLon_E_W
'-------------------------------------------------------------------------
              
         
PUB Str_Speed_Over_Ground
'-------------------------------------------------------------------------
'------------------------┌───────────────────────┐------------------------
'------------------------│ Str_Speed_Over_Ground │------------------------
'------------------------└───────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Speed Over Ground data string                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded
''       Note: In knots [nmi/h]                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded           
RETURN @strSpeedOG
'-------------------------------------------------------------------------


PUB Str_Course_Over_Ground
'-------------------------------------------------------------------------
'------------------------┌────────────────────────┐-----------------------
'------------------------│ Str_Course_Over_Ground │-----------------------
'------------------------└────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: Returns the Course Over Ground data string('0.00'-'359.99')                                
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @StrCourseOG
'-------------------------------------------------------------------------


PUB Str_Mag_Variation
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Str_Mag_Variation │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Magnetic Variation data string                                
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded
''       Note: This important data is not available in some GPS units                                                                 
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strMagVar
'-------------------------------------------------------------------------


PUB Str_MagVar_E_W
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Str_MagVar_E_W │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the 'sign' of Magnetic Variation (See note in DAT)                                
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded
RETURN @strMV_E_W
'-------------------------------------------------------------------------


PUB Str_Altitude_Above_MSL
'-------------------------------------------------------------------------
'-----------------------┌────────────────────────┐------------------------
'-----------------------│ Str_Altitude_Above_MSL │------------------------
'-----------------------└────────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Altitude to Mean See Level (Geoid) data                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strAlt   
'-------------------------------------------------------------------------


PUB Str_Altitude_Unit
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Str_Altitude_Unit │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the MSL Altitude data unit                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strAlt_U


PUB Str_Geoid_Height
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Str_Geoid_Height │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Geoid Height (MSL) to WGS84 ellipsoid                                  
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strGeoidH
'-------------------------------------------------------------------------


PUB Str_Geoid_Height_U
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Str_Geoid_Height_U │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the unit of the Geoid Height                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strGeoidH_U
'-------------------------------------------------------------------------


PRI Concurent_NMEA_Receiver|chr,h0,h1,v0,v1,cks,cks_Rx,cks_OK
'-------------------------------------------------------------------------
'-----------------------┌─────────────────────────┐-----------------------
'-----------------------│ Concurent_NMEA_Receiver │-----------------------
'-----------------------└─────────────────────────┘-----------------------
'-------------------------------------------------------------------------
'     Action: -Reads NMEA sentences and preprocesses them before parsing
'             -Cheks cheksum
'             -Meanwhile update some counters
'             -Copies valid strings (from a sentence) into strBuffer1                                  
' Parameters: None                                 
'    Results: Last received (preprocessed) NMEA sentece in strBuffer1                                                                
'+Reads/Uses: None                                               
'    +Writes: None                                    
'      Calls: None
'       Note: The interpreter for this procedure runs in a separate COG                                                                 
'-------------------------------------------------------------------------

nmeaCntr0~                           'Initialize NMEA sentence counters
nmeaCntr1~
nmeaCntr2~
rmcCntr~
ggaCntr~
gllCntr~
gsvCntr~
gsaCntr~

REPEAT                               'Continuous reading of NMEA sentences
                                     'until POWER OFF or RESET. A separate
                                     'SPIN interpreter is devoted to the
                                     'processing of the tokens of this
                                     'procedure
  
  cks_OK := FALSE                    'To drop into next loop
  chr :=  GPS_UART.Rx
  
  REPEAT UNTIL cks_OK                'Repeat until a received complete 
  '                                  'NMEA sentence is correct
                
    REPEAT WHILE chr <> "$"          'Wait for the start ($) of an NMEA 
      chr :=  GPS_UART.Rx            'sentence

    nmeaCntr0++                      'Increment started NMEA sentence cntr
                                        
    cptr~                            'Initialise char pointer to strBuffer                         
    cks~                             'Initialise running checksum
          
    chr := GPS_UART.Rx               'Get 1st data character after "$"
           
    REPEAT WHILE chr <> _CR          'Read data char until sentence ends
                                     '(or strBuffer is full!)
     'Check received character
     
      IF chr == "*"                  '2 checksum bytes will follow!  
        strBufferRx[cptr++] := 0     'Terminate final data string, though
        h0:=GPS_UART.Rx              'Read 1st checksum control hex char
        h1:=GPS_UART.Rx              'Read 2nd checksum control hex char
         
      ELSE                           'Data or separator char received
      
        cks ^= chr                   'XOR the received byte with running
                                     'checksum. Final result of these
                                     'XORs will be checked with two
                                     'received hex characters at the
                                     'end, after "*", of the NMEA sentence
                                     
        'Decode and place chr into strBuffer  (Hot spot of code, 4 lines)                                
        IF chr == ","                'Separator character received
          strBufferRx[cptr++] := 0   'Terminate data string in buffer
        ELSE                         'Data character received     
          strBufferRx[cptr++] := chr 'Append character to data string

      IF cptr < _MAX_NMEA_SIZE       'Check not to overrun strBuffer(!)
                                     'There can be some noise in the       
                                     'channel or at least good to prepare
                                     'for it. Prop can freeze or reboot
                                     'after such overrun, and that is not
                                     'nice during travel, to say the least
                                     
        chr := GPS_UART.Rx           'Read next char from NMEA stream
      ELSE
        chr := _CR                   'Buffer is full. Something went
                                     'wrong. Mimic <CR> reception to get
                                     'out of here       
      
    'Decode checksum byte sent by the GPS as 2 hex characters: first High,
    'then Low Nibble. Result should be the same as our running XOR value
    '
    '       Checksum =  (1st Hex value) * 16 + (2nd Hex value)
    '
    'First calculate values v0, v1 for hex digits h0, h1
    CASE h0
      $30..$39:v0 := h0 - $30        '"0..9" to 0..9
      $41..$46:v0 := h0 - $37        '"A..F" to 10..16
    CASE h1
      $30..$39:v1 := h1 - $30        '"0..9" to 0..9
      $41..$46:v1 := h1 - $37        '"A..F" to 10..16 
    'Then calculate sent checksum
    cks_Rx := (v0 << 4) + v1         '<<4 stands for *16
      
    rXCks := cks_Rx                  'For debug 
    cCCks := cks
      
    cks_OK := (cks_Rx == cks)        'Check sums.

    IF NOT cks_OK                    'If checksum failed
      nmeaCntr2++                    'Incr. counter of failed sentences

  'It is interesting, or better to say, sad to see, that this very simple
  'checksum algorithm is missed or miscalculated in some GPS NMEA parsers
  'published at Obex. The object that does not calculate it has other
  'serious problems. The corrected 'plus' object miscalculates the
  'checksum and that is even worst, since it discards about half the
  'sentences with all the correct and fresh nav/sat info within.          
  
  'Anyway, if we are here than a complete and correct NMEA sentence was
  'received! Its relevant data are collected in strBufferRx as a
  'continuous package of zero ended strings. strBufferRx may contain null
  'strings, as well. These null strings are "between" two adjacent zero
  'bytes. They occur when the GPS unit does not output data for a given
  'field. Even in that case the GPS transmits the delimiter (,) for the
  'empty field and that comma will be turned into zero by this receiver

  'Move verified NMEA data strings into strBuffer1 for data queue for
  'decoding
  nmeaCntr1++                      'Increment verified sentence counter

  REPEAT WHILE cptr1               'If cptr1 not zero then 'Decoder' did
                                   'not copy strBuffer1 into strBuffer2
                                   'yet. Wait for that. That is a very
                                   'short time, usually.
                                   
  'Now strBuffer1 can be accessed                                 
  BYTEFILL(@strBuffer1, 0, _MAX_NMEA_SIZE)   'Clean up container
  BYTEMOVE(@strBuffer1, @strBufferRx, cptr)  'Copy data
  
  cptr1 := cptr      'Signal a not empty strbuffer1 to the Decoder
  
  'The checksum calculation and the data transfer take about much less
  'than 1 ms. However, the 'Decoder' process can last as long as 1-2 ms.
  'Events can sometime coincide in a way that 'Receiver' has to wait with
  'the data copy for that long. At the highest 115_200 baud rate more than
  '16 characters may accumulate in the UART's receiver buffer during this
  'time. FullDuplexSerial's 16 byte receiver buffer is just not enough for
  'this, but it is fine up to 57_600 baud.  
'-------------------------------------------------------------------------


PRI Concurent_NMEA_Decoder | c0,c1,c2,ps,fp,ac,l
'-------------------------------------------------------------------------
'-----------------------┌────────────────────────┐------------------------
'-----------------------│ Concurent_NMEA_Decoder │------------------------
'-----------------------└────────────────────────┘------------------------
'-------------------------------------------------------------------------
'     Action: -Checks for a not empty strBuffer2
'             -If so then 
'               (After setting RED semaphore to deny external access)
'                decodes its content
'                Sets GREEN semaphore to allow external access to
'                refreshed data  
'             -Checks for a not empty strBuffer1 and for a free access to
'                it   
'             -If so (both) then copies the content of strBuffer1 into
'                strBuffer2                                  
' Parameters: None                                 
'    Results: Refreshed data strings in DAT section                                                               
'+Reads/Uses: None                                               
'    +Writes: None                                    
'      Calls: None
'       Note: -The interpreter for this procedure runs in a separate COG
'                than for main (in COG0) and for 'Concurent_NMEA_Recever'                                                                
'-------------------------------------------------------------------------

REPEAT                           'Until power off or reset

  IF cptr1  'Then copy a not empty strBuffer1 into strBuffer2 for decoding 
    BYTEFILL(@strBuffer2, 0, _MAX_NMEA_SIZE)     'Clean up container
    BYTEMOVE(@strBuffer2, @strBuffer1, cptr1)    'Copy data quickly
    cptr2 := cptr1
    cptr1 := 0                                   'Release strBuffer1

    'Make an array (fieldPtrs) of string pointers to data fields
    'Initialize
    ps := @strBuffer2            'Pointer to strBuffer
    fp := @fieldPtrs             'Pointer to array of field pointers
    ac~                          'Reset argument counter
  
    'Clear fieldPtrs to zero to prevent data mix-up, e.g., in old
    'fashioned RMC sentences where mode field is missing. Or just
    'prepare for some unforeseen errors because they will happen.
    'We are playing here with strings, so we have to be careful.
    c0 := @strNullStr
    REPEAT _MAX_FIELDS
      WORD[fp][ac++] := c0

    ac~                          'Reset again

    'Finally  create the array of pointers (Hot spot of code, 3 lines)
    REPEAT cptr2                 'We do not parse the whole buffer!
      IF BYTE[ps++] == 0         'String delimiter has been reached
        WORD[fp][ac++]:=ps       'Next byte is a pointer to next string
        
      IF ac == _MAX_FIELDS       'Not to overrun fieldPtrs array(!)
        QUIT    
  
    'Pointers ready. Find kind of NMEA sentence
    lastReceived~
    c0 := strBuffer2[2]
    c1 := strBuffer2[3]
    c2 := strBuffer2[4]
    ptrNMEASentType := @strNullStr
    ptrNMEANotRecog := @strNullStr    
    IF(c0=="R")AND(c1=="M")AND(c2=="C")
      lastReceived := _RMC
    ELSEIF(c0=="G")AND(c1=="G")AND(c2=="A")
      lastReceived := _GGA
   
    'We are going to access HUB/DAT area that is regularly read by outer
    'code of the application independently of these Receiver/Decoder
    'processes. Between the Receiver and Decoder we can ensure flawless
    'data transfer, only with the cptr, cptr1, cptr2 global pointers,
    'because we know what, when and why. However, an independently running
    ' 'outer' code that uses this object is out of our timing control.
    'So, let us use a semaphore to keep things organized.
    
    'Suspend the memory access of COG0 to the sensitive area until we are
    'ready with data refresh there.
    
    'Claim a free semaphore: Wait for a free semaphore ID
    REPEAT WHILE (semID_Refresh := LOCKNEW) == -1
    
    LOCKSET(semID_Refresh)   'Set it RED. Processes interpreted by COG0 
                             '(or with any other different COG than for
                             'the Receiver and the Decoder) should wait
                             'for a GREEN signal before accessing GPS
                             'info stored in DAT section by calling the
                             '"Wait_For_New_Data_Decoded" procedure or
                             'by direct check of the semaphore
  
    'Now copy strings from NMEA fields into nav/GPS data in DAT section 
    CASE lastReceived
      _RMC:
        ptrNMEASentType := @rmc
        rmcCntr++       
        c0 := fieldPtrs[0]              'UTC time
        c1 := 11
        BYTEMOVE(@strTime, c0, c1)
        BYTEMOVE(@strDate,fieldPtrs[8],7)
        'Write data Status
        BYTEMOVE(@strGpsStatus,fieldPtrs[1],2)  
        'Check for a Valid status
        c2 := BYTE[@strGpsStatus]
        IF c2 == "A"
          'Write new Valid Nav data   
          BYTEMOVE(@strLatitude,fieldPtrs[2],10)
          BYTEMOVE(@strLat_N_S,fieldPtrs[3],2)
          BYTEMOVE(@strLongitude,fieldPtrs[4],11)
          BYTEMOVE(@strLon_E_W,fieldPtrs[5],2)
          BYTEMOVE(@strSpeedOG,fieldPtrs[6],7)
          BYTEMOVE(@strCourseOG,fieldPtrs[7],7)          
          BYTEMOVE(@strMagVar,fieldPtrs[9],5)
          BYTEMOVE(@strMV_E_W,fieldPtrs[10],2)          
       
      _GGA:
        ptrNMEASentType := @gga
        ggaCntr++
        c0 := fieldPtrs[0]              'UTC time
        c1 := 11
        BYTEMOVE(@strTime, c0, c1)       
        'Write new Nav and GPS Fix data if received
        IF STRSIZE(fieldPtrs[1])
          'Write new valid Nav data from GGA sentence
          BYTEMOVE(@strLatitude,fieldPtrs[1],10)
          BYTEMOVE(@strLat_N_S,fieldPtrs[2],2)
          BYTEMOVE(@strLongitude,fieldPtrs[3],11)
          BYTEMOVE(@strLon_E_W,fieldPtrs[4],2)
          BYTEMOVE(@strAlt,fieldPtrs[8],8)
          BYTEMOVE(@strAlt_U,fieldPtrs[9],2)
          BYTEMOVE(@strGeoidH,fieldPtrs[10],6)
          BYTEMOVE(@strGeoidH_U,fieldPtrs[11],2)
   
      OTHER:
      
    cptr2 := 0           'Meaning that strBuffer2 has been processed and
                         'can be overwritten
                         
    'Data refresh is ready Set Green semaphore (unlock it) to allow data
    'access for other COG(s), especially COG0, to the refreshed nav/sat
    'information stored in the DAT section 
    LOCKCLR(semID_Refresh)
'-------------------------------------------------------------------------


PRI Wait_For_New_Data_Decoded
'-------------------------------------------------------------------------
'---------------------┌───────────────────────────┐-----------------------
'---------------------│ Wait_For_New_Data_Decoded │-----------------------
'---------------------└───────────────────────────┘-----------------------
'-------------------------------------------------------------------------
'     Action: -Waits for a GREEN (not set) semID_Refresh
'             -Releases the semaphore                                
' Parameters: None                                 
'    Results: When procedure returns then semID_Refresh is GREEN and GPS
'             data can be freely accessed                                                               
'+Reads/Uses: None                                               
'    +Writes: None                                    
'      Calls: None                                                                  
'-------------------------------------------------------------------------

'Force calling code (probaply by COG0) to wait for GREEN semaphore  
REPEAT UNTIL (NOT LOCKSET(semID_Refresh))

'If here, then we dropped out from the previous REPEAT, so the semaphore
'was switched to GREEN somewhere in the code, but LOCKSET, during the
'test, set it again RED. Let it remain GREEN if it was switched to GREEN!
'If we did not do this, only a single access for the data would be
'allowed. The second attempt would be blocked again, probably
'unnecessarily, until the 'Decoder' will switch the semaphore GREEN again.     
LOCKCLR(semID_Refresh)             'Requiescat in status  GREEN, then
                                        
LOCKRET(semID_Refresh)             'This doesn't prevent cog0 from
                                   'accessing it afterwards, during the
                                   'following data readouts, it only
                                   'allows the HUB to reassign it again
                                   'when requested.
'-------------------------------------------------------------------------


DAT

strNullStr   BYTE 0                'Null string

'NMEA sentence types that are processed in this version of Driver
rmc          BYTE "RMC", 0         'Recommended Minimum Nav Information(C)                                   
gga          BYTE "GGA", 0         'GPS Fix Data. Time, pos and fix relat.

'-------------------------------------------------------------------------
'-----------------Receved Data from GPS in string format------------------
'-------------------------------------------------------------------------

'General indicators-------------------------------------------------------
'Note that depending on GPS unit type and brand some (most) of these
'indicators are not used by a given GPS device

strGpsStatus BYTE "X", 0     'GPS Status field

                             'A = Autonomous (Data valid)
                             'V = Void (Data invalid, navigation
                             '    receiver warning)
                             
'The next mode field at the end of RMC sentences is only present in NMEA
'version 3.00 or later. Check your receiver!                                    
strGpsMode   BYTE "X", 0     'GPS Mode

                             'A = Autonomous
                             'D = DGPS
                             'E = Estimated, known as Dead Reckoning (DR)
                             'M = Manual Input mode
                             'S = Simulator mode
                             'N = Data not valid
                             
'DGPS: Most of the errors in two receivers close enough to one another
'are identical. Therefore setting a reference receiver on a known point
'allows one to measure the errors in real time on each satellite visible.
'These can then be broadcast over some communications channel to other
'users near the reference station who use this information to correct
'their measurements in real time. This is Differential GPS or D-DPS
'(DGPS). DGPS uses the code phase of GPS signals. There is a carrier
'phase, too, that allows even more precise positioning. See RTK note                             

'Note that setting the Mode Indicator also influences the value of the
'Status field. The Status field will be set to "A" (Data valid) for Mode
'Indicators A and D, and to "V" (Data invalid) for all other values of
'the Mode Indicator.


'WGS84 Navigation Data
strDate      BYTE "DDMMYY", 0      'Last received UTC Date
strTime      BYTE "HHMMSS.SSS", 0  'Last received UTC Time
strLatitude  BYTE "DDMM.MMMM", 0   'Last received Latitude  [degrees]
strLat_N_S   BYTE "X", 0           'N for North, S for South hemisphere
strLongitude BYTE "DDDMM.MMMM", 0  'Last received Longitude [degrees]
strLon_E_W   BYTE "X", 0           'E for East, W for West hemisphere

strSpeedOG   BYTE "VVV.VV", 0      'Last received Speed Over Ground in
                                   '[knots]
                                   
strCourseOG  BYTE "CCC.CC", 0      '-Last received Course Over Ground
                                   'in [degrees]. In no wind condition
                                   'it is the same as True Heading. A  
                                   '"True" direction is measured starting
                                   'at true (geographic) North and moving
                                   'clockwise. In a car Course and Heading
                                   'are usually the same except while
                                   'rallying with high beta angle.
                                   '-Sometime called as Track made good
                                   
strAlt       BYTE "AAAAA.A", 0     'Last received Altitude at Mean Sea
                                   'Level (Geoid)
                                      
strAlt_U     BYTE "M", 0           'Altitude unit (M) for [m]

strGeoidH    BYTE "HHH.H", 0       'Last received Geoid Height referred to
                                   'the WGS84 ellipsoid. It is not a
                                   'measured value but is calculated from
                                   'the position (usually interpolated
                                   'from tabulated data).
                                   'In other words : Mean Sea Level
                                   'relative to WGS84 surface
                                   'Sometimes called Geoid Separation
                                   
strGeoidH_U  BYTE "M", 0           'Geoid Height unit (M) for [m]

strMagVar    BYTE "MM.M", 0        'Last received Magn Variation [degrees]

'Magnetic Variation from a GPS is not a measured value. It is calculated 
'from the position using the WMM2005 or IGRF2005 spherical harmonics 
'models of the core magnetic field of Earth. In some (cheaper) GPS units
'this data is simply interpolated from tables or not calculated at all.
'The field is left empty in that last pitiful case.
'USAGE: Your magnetic compass senses magnetic north that can differ from
'true north more than 20° in many  places on the Earth. From a given true
'course you can obtain magnetic course remembering the memory aid 'IF EAST       
'MAGNETIC IS LEAST, IF WEST MAGNETIC IS BEST' and correct for local
'magnetic variation, as said. If the variation is east of true north, it
'is subtracted from the true course, and west variation is added to the
'true course to obtain magnetic course. True course is a geometric kind of
'thing that you can figure out on a mercator map easily for a rhumb line
'navigation. Magnetic heading is something that you really measure with
'your simple and reliable (but not cheap) magnetic compass. The one that
'does not need batteries, or upgrades from the Internet. In no wind
'condition magnetic heading will be the same as magnetic course. Using
'MAGNETIC NORTH is absolutely not old fashioned in today's navigation even
'if we have smarter and smarter GPS units. E.g. Runway directions
'correspond to the MAGNETIC NORTH reference, VOR station radials are
'numbered clockwise from MAGNETIC NORTH, just to mention a few...
                                    
strMV_E_W    BYTE "X", 0           'E for East, W for West Magnetic Var



{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                  