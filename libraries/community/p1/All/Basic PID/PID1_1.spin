{{
┌──────────────────────────────────────────┐
│ <PID v1.1>                               │
│ Author: <Lee McLaren>                    │               
│ Copyright (c) <2011> <copyright holders> │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘
 
  A very basic SPIN PID implementation based nearly completely on

  http://brettbeauregard.com/blog/2011/04/improving-the-beginners-pid-introduction/

  

  I am multiplying the inputs by 100 before feeding into the PID, and then scale back to the correct value to avoid FP.
  
  For it to work correctly, the PID_Compute needs to be called on a regular basis, eg every 1/4 sec etc. It is important that it
  is regular or it will affect the I


  To use:

To start the PID:
  PUB PID_Init
  PID.PID_SetSP(25)                                       'PID setpoint is before scaling eg, 25c
  PID.PID_SetOutLimits(0,200000,1000)                     'Output limits are before scaling, this will give a 0 - 200 output
  PID.PID_SetTunings(100,2,1)                             'Pick some good numbers for the P, I, D,
  PID.PID_SetState(true)                                  'Enable it.

The input to the PID is 100x eg, 2500 is 25c

Use the PID_SetState to change the mode
  

}}



VAR
  long PID_Auto
  long PID_OutMin, PID_OutMax, PID_Output, PID_Input, PID_LastInput, PID_ITerm
  long PID_KI, PID_KP, PID_KD, PID_Error
  long PID_SP
  long PID_DInput, PID_OutScale



PUB PID_GetSP
  return PID_SP

PUB PID_SetSP(vSP)
  If vSP > 0
    PID_SP := vSP

PUB PID_SETP(vP)
  PID_KP := vP

PUB PID_SETI(vI)
  PID_KI := vI

PUB PID_GETP
  return PID_KP

PUB PID_GETI
  return PID_KI  
  
    
PUB PID_SetTunings(vP, vI, vD )
  If not (vP < 0 OR vI < 0 OR vD < 0)
    PID_KP := vP
    PID_KI := vI
    PID_KD := vD
  
PUB PID_SetOutLimits(vMin, vMax, vScale)
' vMin and vMax are raw before scalling!!!!!
  If (vMin < vMax)
    PID_OutMin := vMin
    PID_OutMax := vMax

    PID_Output <#= PID_OutMax                                'Limit Output max to the OutMax
    PID_Output #>= PID_OutMin                                'Limit Output min to the OutMin

  PID_OutScale := vScale

PUB PID_GetState
' ############################################################################################
' Returns the enable state of PID
  return PID_Auto
  
PUB PID_SetState(Mode)
  If Mode
    If not PID_Auto
      'Changing from Man to Auto
      PID_Auto := True
      PID_Init                                              'ReInit When changing to Auto
  else
    PID_Auto := false                                       'If manual, shut it down

PUB PID_GetInput
  return PID_Input

PUB PID_GetOutput
' Return the unscaled error
  return PID_Output

PUB PID_GetError
  return PID_Error  
  
PUB PID_Init
  PID_LastInput := PID_Input
  PID_ITerm := PID_Output
  PID_ITerm <#= PID_OutMax
  PID_ITerm #>= PID_OutMin

PUB PID_Compute(vInput)
' vInput is the process variable
' returns a scaled output
' Takes raw input in 100th degree and returns scaled and limited output

  PID_Input := vInput

  If PID_Auto
    'Compute all the working error variables
    PID_Error := PID_SP - PID_Input
    PID_ITerm += (PID_KI * PID_Error)
    PID_ITerm <#= PID_OutMax                                'Limit ITerm max to the OutMax
    PID_ITerm #>= PID_OutMin                                'Limit ITerm min to the OutMin
    PID_DInput := PID_Input - PID_LastInput

    'Compute PID Output
    PID_Output := (PID_KP * PID_Error) + PID_ITerm - (PID_KD * PID_DInput)
    PID_Output <#= PID_OutMax                                'Limit ITerm max to the OutMax
    PID_Output #>= PID_OutMin                                'Limit ITerm min to the OutMin

    PID_LastInput := PID_Input
    return PID_Output / PID_OutScale

  else
    return 0

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