
	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32

	.equ GPIO_BASE,    0x3f200000
	.equ GPIO_GPFSEL0, 0x00
	.equ GPIO_GPLEV0,  0x34

	// Incluimos el archivo donde estan todas las funciones
	.include "helpers.s"
	
	// Los inputs para este programa son:
	// W,A

	.equ key_W, 0x2
	.equ key_A, 0x4

	.globl main

	main:
	// x0 contiene la direccion base del framebuffer
	mov x20, x0 // Guarda la dirección base del framebuffer en x20


//------------ Dibujo Principal 

	// Dibujamos Fondo: 

	BL pintar_fondo
	// Cesped
	BL pintar_cesped
	// Tronco
	BL pintar_tronco
	// Hojas
	BL pintar_hojas
	// Nubes
	BL dibujar_nubes


	loop_pulsador:

		// Seteamos el GPIO para poder realizar la lectura de los inputs
		mov x9, GPIO_BASE

		// Atención: se utilizan registros w porque la documentación de broadcom
		// indica que los registros que estamos leyendo y escribiendo son de 32 bits

		// Setea gpios 0 - 9 como lectura
		str wzr, [x9, GPIO_GPFSEL0]

		// Lee el estado de los GPIO 0 - 31
		ldr w10, [x9, GPIO_GPLEV0]

		// And bit a bit mantiene el resultado del bit 2 en w10 (notar 0b... es binario)
		// al inmediato se lo refiere como "máscara" en este caso:
		// - Al hacer AND revela el estado del bit 2
		// - Al hacer OR "setea" el bit 2 en 1
		// - Al hacer AND con el complemento "limpia" el bit 2 (setea el bit 2 en 0)
		
		and w11, w10, 0b00000010
		and w12, w10, 0b00000100

		// si w11 es 0 entonces el GPIO 1 estaba liberado
		// de lo contrario será distinto de 0, (en este caso particular 2)
		// significando que el GPIO 1 fue presionado

		cmp w11 , key_W			// Al presionar la W el cielo se pone nublado
		beq cambiar_cielo

		cmp w12 , key_A			// Al presionar la A se pintan manzanas en el arbol
		beq pintar_manzanas
	
	b loop_pulsador


//--------- Control Inputs

	cambiar_cielo:
		BL dibujar_nubes_nublado

		B loop_pulsador

	pintar_manzanas:
		BL dibujar_manzanas

		B loop_pulsador


//---------------- Infinite Loop ------------------------------------
InfLoop:
	b InfLoop
	