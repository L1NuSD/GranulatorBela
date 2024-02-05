/****************************************************************************
A Csound Granulator instrument using Bela by Keyi Ding
****************************************************************************/


<CsoundSynthesizer>
<CsOptions>
-d -iadc -odac
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1


  opcode BufCt1, i, io
ilen, inum xin
ift        ftgen     inum, 0, -(ilen*sr), 2, 0
           xout      ift
  endop

  opcode BufRec1, k, aikkkk
ain, ift, krec, kstart, kend, kwrap xin
		setksmps	1
kendsmps	=		kend*sr ;end point in samples
kendsmps	=		(kendsmps == 0 || kendsmps > ftlen(ift) ? ftlen(ift) : kendsmps)
kfinished	=		0
krec		init		0
knew		changed	krec ;1 if record just started
 if krec == 1 then
  if knew == 1 then
kndx		=		kstart * sr - 1 ;first index to write minus one
  endif
  if kndx >= kendsmps-1 && kwrap == 1 then
kndx		=		-1
  endif
  if kndx < kendsmps-1 then
kndx		=		kndx + 1
andx		=		kndx
		tabw		ain, andx, ift
  else
kfinished	=		1
  endif
 endif
 		xout		kfinished
  endop

  opcode BufPlay1, ak, ikkkkkk
ift, kplay, kspeed, kvol, kstart, kend, kwrap xin
;kstart = begin of playing the buffer in seconds
;kend = end of playing in seconds. 0 means the end of the table
;kwrap = 0: no wrapping. stops at kend (positive speed) or kstart (negative speed). this makes just sense if the direction does not change and you just want to play the table once 
;kwrap = 1: wraps between kstart and kend
;kwrap = 2: wraps between 0 and kend
;kwrap = 3: wraps between kstart and end of table
;CALCULATE BASIC VALUES
kfin		init		0
iftlen		=		ftlen(ift)/sr ;ftlength in seconds
kend		=		(kend == 0 ? iftlen : kend) ;kend=0 means end of table
kstart01	=		kstart/iftlen ;start in 0-1 range
kend01		=		kend/iftlen ;end in 0-1 range
kfqbas		=		(1/iftlen) * kspeed ;basic phasor frequency
;DIFFERENT BEHAVIOUR DEPENDING ON WRAP:
if kplay == 1 && kfin == 0 then
 ;1. STOP AT START- OR ENDPOINT IF NO WRAPPING REQUIRED (kwrap=0)
 if kwrap == 0 then
kfqrel		=		kfqbas / (kend01-kstart01) ;phasor freq so that 0-1 values match distance start-end
andxrel	phasor 	kfqrel ;index 0-1 for distance start-end
andx		=		andxrel * (kend01-kstart01) + (kstart01) ;final index for reading the table (0-1)
kfirst		init		1 ;don't check condition below at the first k-cycle (always true)
kndx		downsamp	andx
kprevndx	init		0
 ;end of table check:
  ;for positive speed, check if this index is lower than the previous one
  if kfirst == 0 && kspeed > 0 && kndx < kprevndx then 
kfin		=		1
 ;for negative speed, check if this index is higher than the previous one
  else
kprevndx	=		(kprevndx == kstart01 ? kend01 : kprevndx) 
   if kfirst == 0 && kspeed < 0 && kndx > kprevndx then
kfin		=		1
   endif
kfirst		=		0 ;end of first cycle in wrap = 0
  endif
 ;sound out if end of table has not yet reached
asig		table3		andx, ift, 1	
kprevndx	=		kndx ;next previous is this index
 ;2. WRAP BETWEEN START AND END (kwrap=1)
 elseif kwrap == 1 then
kfqrel		=		kfqbas / (kend01-kstart01) ;same as for kwarp=0
andxrel	phasor 	kfqrel 
andx		=		andxrel * (kend01-kstart01) + (kstart01) 
asig		table3		andx, ift, 1	;sound out
 ;3. START AT kstart BUT WRAP BETWEEN 0 AND END (kwrap=2)
 elseif kwrap == 2 then
kw2first	init		1 
  if kw2first == 1 then ;at first k-cycle:
		reinit		wrap3phs ;reinitialize for getting the correct start phase
kw2first	=		0 
  endif
kfqrel		=		kfqbas / kend01 ;phasor freq so that 0-1 values match distance start-end
wrap3phs:
andxrel	phasor 	kfqrel, i(kstart01) ;index 0-1 for distance start-end
		rireturn	;end of reinitialization
andx		=		andxrel * kend01 ;final index for reading the table 
asig		table3		andx, ift, 1	;sound out
 ;4. WRAP BETWEEN kstart AND END OF TABLE(kwrap=3)
 elseif kwrap == 3 then
kfqrel		=		kfqbas / (1-kstart01) ;phasor freq so that 0-1 values match distance start-end
andxrel	phasor 	kfqrel ;index 0-1 for distance start-end
andx		=		andxrel * (1-kstart01) + kstart01 ;final index for reading the table 
asig		table3		andx, ift, 1	
 endif
else ;if either not started or finished at wrap=0
asig		=		0 ;don't produce any sound
endif
  		xout		asig*kvol, kfin
  endop

giSine ftgen 0,0,65536,10,1
giCosine ftgen 0,0,8193,9,1,1,90
giSigmoRise ftgen 0,0,8193,19,0.5,1,270,1
giSigmoFall ftgen 0,0,8193,19,0.5,1,90,1
giPan		ftgen	0, 0, 32768, -21, 1		; for panning (random values between 0 and 1)


instr 1 ;creates the buffer and control record play 
;Record  
	; initialize all 8 digital i/o pins used 
	iSwitchPin1 init 0
	iLED_Pin1 init 1
		
	kSwitch1 digiInBela iSwitchPin1
	digiOutBela kSwitch1, iLED_Pin1
		
    gibuf     BufCt1    10 ;buffer of 10 seconds
    
	gkRecord = kSwitch1
  	if changed(gkRecord) == 1 then
  		prints    "PRESS THE button FOR RECORDING!\n"
    	event     "i",2,0,-1
    	
    endif
    
    
;Play     
    iSwitchPin2 init 2
	iLED_Pin2 init 3
	kSwitch2 digiInBela iSwitchPin2
	
    gkPlay = kSwitch2
    gkOnOff init 0 
    
    kTrig trigger gkPlay, .5, 0
    if  kTrig == 1 then
        gkOnOff += 1
    endif
    
    if changed(gkOnOff) == 1 then
    	if  gkOnOff == 1 then
  			prints    "PRESS THE button FOR PLAYING!\n"
    		event     "i",3,0,-1
    	else
    		turnoff2 2, 1, 2
            gkOnOff = 0
        endif
    endif
    digiOutBela gkOnOff, iLED_Pin2
    
;Granular
	iSwitchPin3 init 4
	iLED_Pin3 init 5
	
	kSwitch3 digiInBela iSwitchPin3
	
	gkGran = kSwitch3
    gkOnOffGran init 0 
    
    kTrigGran trigger gkGran, .5, 0
    if  kTrigGran == 1 then
        gkOnOffGran += 1
    endif
    
    if changed(gkOnOffGran) == 1 then
    	if  gkOnOffGran == 1 then
  			prints    "Granulator Is On!\n"
    		event     "i",4,0,-1
    	else
    		turnoff2 4, 1, 2
            gkOnOffGran = 0
        endif
    endif
    digiOutBela gkOnOffGran, iLED_Pin3
    
	
endin 



instr 2 ;records for 3 seconds and plays it back
          prints    "RECORDING AND PLAYING BACK AFTER 3 SECONDS!\n"
krec      init      0 ;reset krec for multiple triggering
ain       inch      1 ;audio input from channel 1
kplay     BufRec1   ain*0.5, gibuf, krec, 0, 0, 0 ;record buffer without wrap
krec      =         1
endin

instr 3 
aout,k0   BufPlay1  gibuf, gkOnOff, 1, 0.5, 0, 0, 1 ;play back buffer
          out       aout
endin 

instr 4

ana01 chnget "analogIn0"
ana02 chnget "analogIn1"
ana03 chnget "analogIn2"
ana04 chnget "analogIn3"

gkamp = 0.5 ;+ ana04 * 0.8 
gkspeed = 10
gkgrainrate = ana01 * 50 + 5
gkgrainsize = ana02 * 50 + 5 
gkcent = 0; p7 transpositionin cent
gkposrand = 20 ;p8 ; time position randomness (offset) of the pointer in ms
gkcentrand = 0 ;  p9 transposition randomness in cents
ipan = 0; panning narrow(0) to wide(1) 
idist			= 0.5;p11		; grain distribution (0=periodic, 1=scattered)

/* get lentgh of audio file for transposition and time pointer*/
ifilen tableng gibuf
ifildur = ifilen / sr

/*sync input*/
async = 0.0; disable external sync 

/*grain envelope*/
kenv2amt = 0;no secondary enveloping
ienv2tab = -1; default secondary envelope
ienv_attack = giSigmoRise;  attack envelope
ienv_decay = giSigmoFall; decay envelope
ksustain_amount = 0; time(infraction of grain duration) as sustain level for each  grain.
ka2dratio = 0.5; balance between attack and decay

/*amplitude*/
igainmask = -1; no gain masking 

/*transposition*/
gkcentrand rand gkcentrand; random transposition
iorig = 1/ ifildur; original pitch
kwavfreq = iorig * cent(gkcent + gkcentrand)

/*other pitch related params(disabled)*/
ksweepshape =0 ; no frequency sweep
iwavfreqstarttab = -1; default frequency sweep start
iwavfreqendtab = -1; default frequency sweep
awavfm = 0; no FM input
ifmamptab = -1; default FM scaling (=-1)
kfmenv = -1 ; default FM envelope(flat)

/*trainlet related params(disabled)*/
icosine = giCosine; cosine ftable
kTrainCps = gkgrainrate; set trainlet cps equal to grain rate for single-cycle trainlet in each grain 
knumpartials = 1; number of partials in trainlet
kchroma  = 1; 

/*pannings, using channel mask*/
imid = .5; center
ileftmost = imid - ipan/2
irightmost = imid + ipan/2
giPanthis ftgen 0, 0, 32768, -24, giPan, ileftmost, irightmost; reScales gipan according to ipan
			tableiw  0, 0, giPanthis; change index 0
			tableiw 32766, 1, giPanthis; and 1 for ichannelmasks
ichannelmasks = giPanthis; ftable for panning

/*random gain masking (disabled)*/
krandommask = 0;

/*source waveforms*/
kwaveform1		= gibuf	; source waveform
kwaveform2		= gibuf	; all 4 sources are the same
kwaveform3		= gibuf
kwaveform4		= gibuf
iwaveamptab		= -1		; (default) equal mix of source waveforms and no amplitude for trainlets

/*timepointers*/ 
afilposphas phasor gkspeed / ifildur

/*generate random deviaton of the time pointer*/
gkposrandsec = gkposrand / 1000 ; ms -> sec
gkposrand = gkposrandsec / ifildur ; phase value (0-1)
gkrndpos linrand gkposrand; ranodm offset in phase values

/*add random deviation to the time pointer*/
asamplepos1		= afilposphas + gkrndpos; resulting phase values (0-1)
asamplepos2		= asamplepos1
asamplepos3		= asamplepos1	
asamplepos4		= asamplepos1

/*original key for each source waveform*/
kwavekey1		= 1
kwavekey2		= kwavekey1	
kwavekey3		= kwavekey1
kwavekey4		= kwavekey1

/* maximum number of grains per k-period*/
imax_grains		= 100	

aL, aR partikkel gkgrainrate, idist, -1, async, kenv2amt, ienv2tab, ienv_attack, ienv_decay,
		ksustain_amount, ka2dratio, gkgrainsize, gkamp, igainmask, kwavfreq,ksweepshape, 
		iwavfreqstarttab, iwavfreqendtab, awavfm, ifmamptab,kfmenv,icosine, kTrainCps,
		knumpartials, kchroma, ichannelmasks, krandommask,  kwaveform1, kwaveform2,
		kwaveform3, kwaveform4,iwaveamptab, asamplepos1, asamplepos2, asamplepos3,
		asamplepos4,kwavekey1, kwavekey2, kwavekey3, kwavekey4, imax_grains
	
outs aL, aR

endin 

</CsInstruments>
<CsScore>
i 1 0 1000
</CsScore>
</CsoundSynthesizer>


<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>240</r>
  <g>240</g>
  <b>240</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
