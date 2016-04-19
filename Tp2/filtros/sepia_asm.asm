section .data
DEFAULT REL

section .rodata
quitarBasura: db 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF
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
psrldq xmm0, 3			 ; XMM0 = [ 00 | 00 | 00 | B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 ]
psrldq xmm1, 2			 ; XMM1 = [ 00 | 00 | B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 ]
psrldq xmm2, 1			 ; XMM2 = [ 00 | B1 | G1 | R1 | A1 | B2 | G2 | R2 | A2 | B3 | G3 | R3 | A3 | B4 | G4 | R4 ]

pand xmm0, [quitarBasura] ; XMM0 = [ 00 | 00 | 00 | B1 | 00 | 00 | 00 | B2 | 00 | 00 | 00 | B3 | 00 | 00 | 00 | B4 ]
pand xmm1, [quitarBasura] ; XMM1 = [ 00 | 00 | 00 | G1 | 00 | 00 | 00 | G2 | 00 | 00 | 00 | G3 | 00 | 00 | 00 | G4 ]
pand xmm2, [quitarBasura] ; XMM2 = [ 00 | 00 | 00 | R1 | 00 | 00 | 00 | R2 | 00 | 00 | 00 | R3 | 00 | 00 | 00 | R4 ]

paddd xmm0, xmm1    	 ; sumo SIN saturacion
paddd xmm0, xmm2

; XMM0 = [ S1 | S2 | S3 | S4 ]

movdqu xmm3, xmm0
movdqu xmm4, xmm0
movdqu xmm5, xmm0
movdqu xmm6, xmm0
movdqu xmm7, xmm0
movdqu xmm8, xmm0

; XMM0 = XMM(3..7) = [ 0 | 0 | 0 | S1 | 0 | 0 | 0 | S2 | 0 | 0 | 0 | S3 | 0 | 0 | 0 | S4 ]

pmullw xmm3, [multB]
pmulhw xmm4, [multB]

pmullw xmm5, [multR]
pmulhw xmm6, [multR]

pmullw xmm7, [multG]
pmulhw xmm8, [multG]

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


;tiene que haber alguna forma mas eficiente de hacerlo
;¿como elijo los resultados (partes de registros xmm) que quiero pasarle a destination?

pop r15
pop rbx
pop rbp
ret