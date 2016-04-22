section .data
DEFAULT REL

section .rodata
quitarBasura:
saturacion: db 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF
multB: dw 0.2, 0.2, 0.2, 0.2
multG: dw 0.3, 0.3, 0.3, 0.3
multR: dw 0.5, 0.5, 0.5, 0.5

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

xor r10, r10; voy a guardar el corrimiento de la memoria
xor r12, r12; voy a guardar X
xor r13, r13; voy a guardar Y
 
cicloY:

cicloX:
movdqu xmm0, [rdi + r10] ; XMM0 = [ B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 | A4 ]
movdqu xmm1, xmm0
movdqu xmm2, xmm1
movdqu xmm9, xmm1		 ; save
psrldq xmm0, 3			 ; XMM0 = [ 00 | 00 | 00 | B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 ]
psrldq xmm1, 2			 ; XMM1 = [ 00 | 00 | B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 ]
psrldq xmm2, 1			 ; XMM2 = [ 00 | B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 ]

pand xmm0, [quitarBasura] ; XMM0 = [ 00 | 00 | 00 | B1 | 00 | 00 | 00 | B2 | 00 | 00 | 00 | B3 | 00 | 00 | 00 | B4 ]
pand xmm1, [quitarBasura] ; XMM1 = [ 00 | 00 | 00 | G1 | 00 | 00 | 00 | G2 | 00 | 00 | 00 | G3 | 00 | 00 | 00 | G4 ]
pand xmm2, [quitarBasura] ; XMM2 = [ 00 | 00 | 00 | R1 | 00 | 00 | 00 | R2 | 00 | 00 | 00 | R3 | 00 | 00 | 00 | R4 ]

paddd xmm0, xmm1    	 ; sumo SIN saturacion
paddd xmm0, xmm2

; quizas hubo un overflow y me piso el byte de la izquierda, pero estoy seguro de que mas que eso no va a pisar
; XMM0 = [ 00 | S1 | 00 | S2 | 00 | S3 | 00 | S4 ]

movdqu xmm3, xmm0
movdqu xmm4, xmm0
movdqu xmm5, xmm0

; XMM0 = XMM(3..5) = [ S1 | S2 | S3 | S4 ]

mulps xmm3, [multB]
mulps xmm4, [multG]
mulps xmm5, [multR]

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

pcmpgtd xmm6, [saturacion]
pcmpgtd xmm7, [saturacion]
pcmpgtd xmm8, [saturacion]

por xmm3, xmm6
por xmm4, xmm7
por xmm5, xmm8

;AHORA HAY QUE HACER CORRIMIENTOS A LOS REGISTROS, LOS SUMO Y ASI PASO DE UNA VEZ SOLA A MEMORIA LOS CUATRO PIXELES

;luego de estos registros puedo extrar valor a valor con PEXTRD (que me saca la double word
;menos significativa y la deja en un registro). 
;o sino, en ese registro podria redondearlo con ROUNDPS
;(toma dos parametros y una constante, cte=2 asi redondea hacia arriba), luego ver si se paso 
;de 255 y a base de eso escribirlo en la memoria, pero deberia ir uno por uno comparando (es malo?)



pop r15
pop rbx
pop rbp
ret

;CODIGO VIEJO:
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