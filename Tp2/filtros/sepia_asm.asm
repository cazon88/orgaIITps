section .data
DEFAULT REL

section .rodata
saturacion:
quitarBasura: db 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00
multB: dd 0.2, 0.2, 0.2, 0.2
multG: dd 0.3, 0.3, 0.3, 0.3
multR: dd 0.5, 0.5, 0.5, 0.5

section .text
global sepia_asm
;void sepia_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
;                     int src_row_size, int dst_row_size, int alfa);
sepia_asm:
;RDI = *src
;RSI = *dst
;RDX = columnas
;RCX = filas
;R8 = source row
;R9 = destination row
;PILA = alfa

push rbp ;alineada
mov rbp, rsp
push r12 ;desalinada
push r13 ;alineada
xor r12, r12; voy a guardar X
xor r13, r13; voy a guardar Y
 
movdqu xmm12, [multB]
movdqu xmm13, [multG]
movdqu xmm14, [multR]
movdqu xmm15, [quitarBasura]
jmp .cicloX

.cicloY:
xor r12, r12
add r13, 1
cmp r13, rcx
je .terminar
jmp .cicloX

.cicloX:
movdqu xmm0, [rdi] 		 ; XMM0 = [ B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 | A4 ]
movdqu xmm1, xmm0
movdqu xmm2, xmm0
movdqu xmm9, xmm0		 ; save
psrldq xmm1, 1			 ; XMM1 = [ G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 | A4 | 00 ]
psrldq xmm2, 2			 ; XMM2 = [ R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 | A4 | 00 | 00 ]
psrldq xmm9, 3			 ; XMM3 = [ A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 | A4 | 00 | 00 | 00 ]

pand xmm0, xmm15 ; XMM0 = [ B1 | 00 | 00 | 00 | B2 | 00 | 00 | 00 | B3 | 00 | 00 | 00 | B4 | 00 | 00 | 00 ]
pand xmm1, xmm15 ; XMM1 = [ G1 | 00 | 00 | 00 | G2 | 00 | 00 | 00 | G3 | 00 | 00 | 00 | G4 | 00 | 00 | 00 ]
pand xmm2, xmm15 ; XMM2 = [ R1 | 00 | 00 | 00 | R2 | 00 | 00 | 00 | R3 | 00 | 00 | 00 | R4 | 00 | 00 | 00 ]

paddd xmm0, xmm1    	 ; sumo SIN saturacion
paddd xmm0, xmm2

movdqu xmm3, xmm0
movdqu xmm4, xmm0
movdqu xmm5, xmm0

cvtdq2ps xmm3, xmm3  ;los convierto en floats
cvtdq2ps xmm4, xmm4
cvtdq2ps xmm5, xmm5

; XMM0 = XMM(3..5) = [ S1 | S2 | S3 | S4 ]

mulps xmm3, xmm12 ; xmm12 = multB
mulps xmm4, xmm13 ; xmm13 = multG
mulps xmm5, xmm14 ; xmm14 = multR

; XMM3 = [ S1*0.2 | S2*0.2 | S3*0.2 | S4*0.2 ] con floats
; XMM4 = [ S1*0.3 | S2*0.3 | S3*0.3 | S4*0.3 ]
; XMM5 = [ S1*0.5 | S2*0.5 | S3*0.5 | S4*0.5 ]

cvtps2dq xmm6, xmm3 ;paso de float a integer
cvtps2dq xmm7, xmm4
cvtps2dq xmm8, xmm5

movdqu xmm3, xmm6
movdqu xmm4, xmm7
movdqu xmm5, xmm8

; XMM3 = XMM6 = [ S1*0.2 | S2*0.2 | S3*0.2 | S4*0.2 ] con integers
; XMM4 = XMM7 = [ S1*0.3 | S2*0.3 | S3*0.3 | S4*0.3 ]
; XMM5 = XMM8 = [ S1*0.5 | S2*0.5 | S3*0.5 | S4*0.5 ]

;BREAKPOINT1

pcmpgtd xmm6, xmm15 ; xmm15 = saturacion
pcmpgtd xmm7, xmm15 ; xmm15 = saturacion
pcmpgtd xmm8, xmm15 ; xmm15 = saturacion

por xmm3, xmm6
por xmm4, xmm7
por xmm5, xmm8

pand xmm9, xmm15 ; xmm15 = quitarBasura
pand xmm3, xmm15
pand xmm4, xmm15
pand xmm5, xmm15

; XMM3 = [ R1 | 00 | 00 | 00 | R2 | 00 | 00 | 00 | R3 | 00 | 00 | 00 | R4 | 00 | 00 | 00 ]
; XMM4 = [ G1 | 00 | 00 | 00 | G2 | 00 | 00 | 00 | G3 | 00 | 00 | 00 | G4 | 00 | 00 | 00 ]
; XMM5 = [ B1 | 00 | 00 | 00 | B2 | 00 | 00 | 00 | B3 | 00 | 00 | 00 | B4 | 00 | 00 | 00 ]
; XMM9 = [ A1 | 00 | 00 | 00 | A2 | 00 | 00 | 00 | A3 | 00 | 00 | 00 | A4 | 00 | 00 | 00 ]

;BREAKPOINT2

pslldq xmm4, 1
pslldq xmm5, 2
pslldq xmm9, 3

paddd xmm9, xmm3
paddd xmm9, xmm4
paddd xmm9, xmm5

; XMM4 = [ B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 | A4 ]

movdqu [rsi], xmm9
lea rsi, [rsi + 16]
lea rdi, [rdi + 16]
add r12, 4
cmp r12, rdx ;comparo para ver si ya termine esta fila
je .cicloY
jmp .cicloX

.terminar:
pop r13
pop r12
pop rbp
ret

;CODIGO VIEJO:

;luego de estos registros puedo extrar valor a valor con PEXTRD (que me saca la double word
;menos significativa y la deja en un registro). 
;o sino, en ese registro podria redondearlo con ROUNDPS
;(toma dos parametros y una constante, cte=2 asi redondea hacia arriba), luego ver si se paso 
;de 255 y a base de eso escribirlo en la memoria, pero deberia ir uno por uno comparando (es malo?)

;movdqu xmm3, xmm0
;movdqu xmm4, xmm0
;movdqu xmm5, xmm0
;movdqu xmm6, xmm0
;movdqu xmm7, xmm0
;movdqu xmm8, xmm0

;pmullw xmm3, [multB]
;pmulhw xmm4, [multB]

;pmullw xmm5, [multR]
;pmulhw xmm6, [multR]

;pmullw xmm7, [multG]
;pmulhw xmm8, [multG]

; XMM3 = BL
; XMM4 = BH
; XMM5 = RL
; XMM6 = RH
; XMM7 = GL
; XMM8 = GH

; XMM3 = [ S1BL | S2BL ]
; XMM4 = [ S3BH | S4BH ]
; XMM5 = [ S1B | S2B ]
; XMM6 = [ S1B | S2B ]
; XMM7 = [ S1B | S2B ]
; XMM8 = [ S1B | S2B ]

;POSIBILIDADES:
;ALGO QUE MULTIPLIQUE Y YA ME LO DEJE DE TAMAÑO 1B
;EXTRACTPS
;
;CVTPS2DQ

;EXPERIMENTO POSIBLE:
;USAR PACKSSWB Y PACKUSWB, 

;OTRO EXPERIMENTO POSIBLE:
;CAMBIAR DE LUGAR LOS ACCESOS A MEMORIA QUE ESTAN ANTES DE CICLOY Y PONERLOS DENTRO DEL CICLO, PARA VER QUE TAN CARO ES ACCEDER A MEMORIA







; MAS CODIGO VIEJO
; XMM0 = XMM(3..5) = [ S1 | S2 | S3 | S4 ]

;mulps xmm3, xmm12 ; xmm12 = multB
;mulps xmm4, xmm13 ; xmm13 = multG
;mulps xmm5, xmm14 ; xmm14 = multR

; XMM3 = [ S1*0.2 | S2*0.2 | S3*0.2 | S4*0.2 ] con floats
; XMM4 = [ S1*0.3 | S2*0.3 | S3*0.3 | S4*0.3 ]
; XMM5 = [ S1*0.5 | S2*0.5 | S3*0.5 | S4*0.5 ]

;cvtps2dq xmm6, xmm3 ;paso de float a integer
;cvtps2dq xmm7, xmm4
;cvtps2dq xmm8, xmm5

;movdqu xmm3, xmm6
;movdqu xmm4, xmm7
;movdqu xmm5, xmm8

; XMM3 = XMM6 = [ S1*0.2 | S2*0.2 | S3*0.2 | S4*0.2 ] con integers
; XMM4 = XMM7 = [ S1*0.3 | S2*0.3 | S3*0.3 | S4*0.3 ]
; XMM5 = XMM8 = [ S1*0.5 | S2*0.5 | S3*0.5 | S4*0.5 ]

;BREAKPOINT1

;pcmpgtd xmm6, xmm15 ; xmm15 = saturacion
;pcmpgtd xmm7, xmm15 ; xmm15 = saturacion
;pcmpgtd xmm8, xmm15 ; xmm15 = saturacion

;por xmm3, xmm6
;por xmm4, xmm7
;por xmm5, xmm8

;pand xmm9, xmm15 ; xmm15 = quitarBasura
;pand xmm3, xmm15
;pand xmm4, xmm15
;pand xmm5, xmm15

; XMM3 = [ R1 | 00 | 00 | 00 | R2 | 00 | 00 | 00 | R3 | 00 | 00 | 00 | R4 | 00 | 00 | 00 ]
; XMM4 = [ G1 | 00 | 00 | 00 | G2 | 00 | 00 | 00 | G3 | 00 | 00 | 00 | G4 | 00 | 00 | 00 ]
; XMM5 = [ B1 | 00 | 00 | 00 | B2 | 00 | 00 | 00 | B3 | 00 | 00 | 00 | B4 | 00 | 00 | 00 ]
; XMM9 = [ A1 | 00 | 00 | 00 | A2 | 00 | 00 | 00 | A3 | 00 | 00 | 00 | A4 | 00 | 00 | 00 ]

;BREAKPOINT2

;pslldq xmm4, 1
;pslldq xmm5, 2
;pslldq xmm9, 3