
global ldr_asm

section .data

section .text
;void ldr_asm    (
	;unsigned char *src,
	;unsigned char *dst,
	;int filas,
	;int cols,
	;int src_row_size,
	;int dst_row_size,
	;int alpha)

;--------------Convencion C---------------
;- Preservar: RBX, R12, R13, R14, R15    -
;- Retornar en: RAX o XMM0               -
;- Recibo en: RDI, RSI, RDX, RCX, R8, R9 -
;- Recibo en: XMM0 a XMM7                -
;- Recibo en Pila                        - 
;-----------------------------------------

ldr_asm:
	push RBP				;Alineada
	mov RBP, RSP		;Se crea el Stack F
.desempaquetado:
;Pasar a float. ¿Se pasa solo agrandando los bytes o hay que configurarlo como float?
;AND with a mask to zero out the odd bytes (PAND)
;Unpack from 16 bits to 32 bits (PUNPCKLWD with a zero vector)
;Convert 32 bit ints to floats (CVTDQ2PS)

;FLOAT 32bit
;[0 | 0|1|1|1|1|1|0|0 | 0|1|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0] = 0.15625
;sign | exponent(8b)   | fraction(23b)
; +      (124-127 = -3) 
;1.01 * 2⁻³
;0.00101 = 2⁻³ + 2⁻⁵ = 0.15625

;notacion: (m,e) = m * b^e
; m = mantisa
; b = base
; e = exponente

.ciclo:

;1 ciclo para recorrer toda la matriz
;1 ciclo para recorrer los pixeles vecinos

;En ciclo vecinos:

;Pixel procesado P19:
;[P17|P18|P19|P20|P21|P22|P23|P24]
;[P09|P10|P11|P12|P13|P14|P15|P16]
;[P01|P02|P03|P04|P05|P06|P07|P08]

;P01 - P02 - P03 - P04 - P05 -  P09 - P10 -
;P11 - P12 - P13 - P17 - P18 - P19 - P20 - 
;P21 - P25 - ....

;[    P01    |     P02    |     P03   |    P04   ]
;[R1|G1|B1|A1|R2|G2|B2|A2|R3|G3|B3|A3|R4|G4|B4|A4] 
;[00|R1|G1|B1|A1|R2|G2|B2|A2|R3|G3|B3|A3|R4|G4|B4] 
;[00|00|R1|G1|B1|A1|R2|G2|B2|A2|R3|G3|B3|A3|R4|G4] 
;       X           X           X           X

;Para el primer 
;¿Como hacemos con P05?

.empaquetado:		

.fin:
	pop RBP
	ret
 
