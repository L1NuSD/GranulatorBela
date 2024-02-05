# Granulator Bela

Granulator is an in-progress project made using Csound with Bela mini. It is a granular instrument that granulizes audio using potentiometers, push buttons and an audio input. 
### Controlling
User could plug in a synth to the audio input and use the push button to start record and playback. LED are used every time the user start/stop buffer recording and playback. After recording, the user could use the third push button to enable granulation and use separate potentiometers for controlling audio grain size and grain rate.  

### Csound 
The code running on the Bela mini is written using Csound. User-define opcode Bufrecord and Bufplay is used for recording and playback audio. The Partikkel opcode is used for granulizing audio. 
### Future Plan
The project is being tested on the integration with sensors and further designs are being considered for final present. 