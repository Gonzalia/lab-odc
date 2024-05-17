.equ SCREEN_WIDTH, 		640
.equ SCREEN_HEIGH, 		480	

//-------- Funciones logicas

	calcular_pixel:
		// 	Parametros:
		// 	x3 -> Pixel X.
		// 	x4 -> Pixel Y.
		// 	Return x0 -> Posición (x,y) en la imgen.

		mov x0, SCREEN_WIDTH				// x0 = 640.
		mul x0, x0, x4						// x0 = 640 * y.		
		add x0, x0, x3						// x0 = (640 * y) + x.
		lsl x0, x0, 2						// x0 = ((640 * y) + x) * 4.
		add x0, x0, x20						// x0 = ((640 * y) + x) * 4 + A[0].
	ret										// Seguimos con la siguiente instrucción. -> BR x30
	pintar_pixel:
		// 	Parametros:
		// 	x1 -> Pixel X.
		// 	x2 -> Pixel Y.
		// x10 -> Color

		// Guardamos los valores originales.
		SUB SP, SP, 24 										
		STUR x30, [SP, 16]
		STUR x3, [SP, 8]
		STUR x4, [SP, 0]

		// Chequeamos que las coordenadas esten dentro de la pantalla, si no lo estan, no pintamos
		cmp x1, SCREEN_WIDTH
		b.ge no_paint
		cmp x2, SCREEN_HEIGH
		b.ge no_paint

		mov x3, x1                          // x3 -> Pixel X
		mov x4, x2                          // x4 -> Pixel Y

		BL calcular_pixel 					// Calculamos la direccion del pixel a pintar

		stur w10, [x0]                      // Pintamos el Pixel

		no_paint:    
		// Devolvemos los valores originales.
		LDR x4, [SP, 0]					 			
		LDR x3, [SP, 8]
		LDR x30, [SP, 16]
		ADD SP, SP, 24	

	ret

	si_pixel_en_circulo_pintar:
		// Verificamos si el pixel (x1 , x2) pertenece al circulo y si lo hace, lo pintamos
		// Parametros:
		// (x1 , x2) -> Pixel que estamos analizando
		// (x4 , x5) -> Pixel centro del circulo
		// x3 -> Radio del Circulo
		// x10 -> Color

		// Si (x1-x4)² + (x2-x5)² ≤ x3² => (x1,x2) esta dentro del circulo

		// Guardamos los valores originales.
		SUB SP, SP, 32 										
		STUR x30, [SP, 24]
		STUR x15, [SP, 16]
		STUR x14, [SP, 8]
		STUR x13, [SP, 0]

		mul x15,x3,x3           // x15 -> r * r

		sub x13, x1, x4         // x13 -> (x1-x4) 
		mul x13, x13, x13       // x13 -> (x1-x4) * (x1-x4)

		sub x14, x2, x5         // x14 -> (x2-x5)
		mul x14, x14, x14       // x14 -> (x2-x5) * (x2-x5)
		
		add x13, x13, x14       // x13 -> (x1-x4)² + (x2-x5)²
		cmp x13, x15

		b.gt outside            // Si no esta dentro, no pinto
		
		bl pintar_pixel          // Si estoy dentro, pinto el pixel (x1 , x2)

		outside:
		// Devolvemos los valores originales.
		LDR x13, [SP, 0]					 			
		LDR x14, [SP, 8]
		LDR x15, [SP, 16]
		LDR x30, [SP, 24]
		ADD SP, SP, 32
	ret

	dibujar_circulo:
		// Circulo de radio r centrado en (x0 , y0)
		// Parametros:
		// x3 -> r
		// (x4 , x5) -> (x0,y0)
		// x10 -> Color

		// Guardamos los valores originales.
		SUB SP, SP, 56 										
		STUR x30, [SP, 48]
		STUR x9, [SP, 40]
		STUR x8, [SP, 32]
		STUR x7, [SP, 24]
		STUR x6, [SP, 16]
		STUR x2, [SP, 8]
		STUR x1, [SP, 0]

		// Calculamos el tamaño del lado del minimo cuadrado que contiene el circulo    
		add x6, x3, x3                              // x6 -> r + r
		
		subs x1, x4, x3                             // x1 -> x0 - r
		b.lt set_x1_to_0                            // Si da negativo entonces x1 tiene que ser 0
		b skip_x1
		
		set_x1_to_0: 
			add x1, xzr, xzr                        // x1 -> 0
		skip_x1:
			subs x2, x5, x3                         // x1 -> y0 - r
			b.lt set_x2_to_0                        // Si da negativo entonces x2 tiene que ser 0
			b skip_x2
		set_x2_to_0: 
			add x2, xzr, xzr                        // x2 -> 0
		skip_x2:

		mov x7, x1                                  // x7 -> x1
		mov x9, x6                                  // x9 -> x6

		// Ahora recorro todo el cuadrado que contiene el circulo y solo pinto los pixeles que pertenecen a el.
		loop_1:                                    
			cbz x9, endloop_1
			cmp x2, SCREEN_HEIGH
			b.ge endloop_1
			mov x1, x7
			mov x8, x6
			loop_0:
				cbz x8, endloop_0
				cmp x1, SCREEN_WIDTH
				b.ge endloop_0
				bl si_pixel_en_circulo_pintar
				add x1, x1, 1
				sub x8, x8, 1
				b loop_0

		endloop_0:
			add x2, x2, 1
			sub x9, x9, 1
			b loop_1
		
		endloop_1:
		// Devolvemos los valores originales.
		LDR x1, [SP, 0]					 			
		LDR x2, [SP, 8]					 			
		LDR x6, [SP, 16]					 			
		LDR x7, [SP, 24]					 			
		LDR x8, [SP, 32]					 			
		LDR x9, [SP, 40]
		LDR x30, [SP, 48]
		ADD SP, SP, 56
	ret

	dibujar_cuadrado:
		// 	Parametros:
		// 	w10 -> Color.
		//	x1 -> Ancho.
		//	x2 -> Alto.
		// 	x3 -> Pixel X.
		// 	x4 -> Pixel Y.

		// Guardamos los valores originales.
		SUB SP, SP, 40 										
		STUR x30, [SP, 32]
		STUR x13, [SP, 24]
		STUR x12, [SP, 16]
		STUR x11, [SP, 8]
		STUR x9,  [SP, 0]

		BL calcular_pixel 					// Calculamos el pixel a dibujar con la función "calcular_pixel". Retorna x0.
		
		mov x9, x2							// x9 = x2 --> A x9 le guardamos el alto de la imagen.
		mov x13, x0							// x13 = x0 --> A x13 le guardamos la posición de x0 calculada.	
		pintar_cuadrado:
			mov x11, x1						// x11 = x1 --> A x11 le asignamos el ancho de la fila.
			mov x12, x13					// x12 = x13 --> A x12 le guardamos x13 (En esta parte de la ejecucción a x12 se le guarda el pixel inicial de la fila).
			color_cuadrado:
				stur w10, [x13]				// Memory[x13] = w10 --> A x13 le asignamos en memoria el color que respresenta w10.
				add x13, x13, 4				// w13 = w13 + 4 --> x13 se mueve un pixel hacia la derecha.
				sub x11, x11, 1				// w11 = w11 - 1 --> x11 le restamos un pixel de ancho.
				cbnz x11, color_cuadrado	// Si x11 no es 0 (la fila no se termino de pintar), seguimos pintandola.
				mov x13, x12				// En esta parte, ya se termino de pintar la fila. x13 = x12. Volvemos al pixel de origen de la fila.
				add x13, x13, 2560			// x13 = x13 + 2560. La constante 2560 es el total de pixeles de una fila, entoces si lo sumamos es como dar un salto de linea.
				sub x9, x9, 1				// x9 = x9 - 1 --> Le restamos 1 al alto de la fila.
				cbnz x9, pintar_cuadrado	// Si el alto no es 0, es porque aún no se termino de pintar.

		// Devolvemos los valores originales.
		LDR x9, [SP, 0]					 			
		LDR x11, [SP, 8]					 			
		LDR x12, [SP, 16]					 			
		LDR x13, [SP, 24]					 			
		LDR x30, [SP, 32]					 			
		ADD SP, SP, 40
	ret




//------ Dibujos

    pintar_cesped:
		SUB SP, SP, 8 						
		STUR X30, [SP, 0]

		movz w10, 0x41, lsl 16				
		movk w10, 0xAE46, lsl 0

		mov x1, 640
		mov x2, 70
		mov x3, 10
		mov x4, 410
		BL dibujar_cuadrado


		LDR X30, [SP, 0]						
			ADD SP, SP, 8	
		ret


    pintar_tronco:
		SUB SP, SP, 8 						
		STUR X30, [SP, 0]

		movz w10, 0x7F, lsl 16				
		movk w10, 0x4F2C, lsl 0

		mov x1, 30
		mov x2, 150
		mov x3, 500
		mov x4, 280
		BL dibujar_cuadrado


		LDR X30, [SP, 0]					
		ret


    dibujar_nubes:
    SUB SP, SP, 8 					
		STUR X30, [SP, 0]
		
        // Nube
		movz w10, 0xFF, lsl 16              
		movk w10, 0xFFFF, lsl 00
		mov x3, 60                        	// 	x3 -> Radio
		mov x4, 50                  		// 	x4 -> x0
		mov x5, 10                         // 	x4 -> y0
		BL dibujar_circulo

       
		mov x3, 60                        	
		mov x4, 100                  		
		mov x5, 10                         
		BL dibujar_circulo

        
		mov x3, 80                        
		mov x4, 150                  	
		mov x5, 10                        
		BL dibujar_circulo

       
		mov x3, 60                        
		mov x4, 210                  	
		mov x5, 10                        
		BL dibujar_circulo

       
		mov x3, 30                        
		mov x4, 270                  	
		mov x5, 10                        
		BL dibujar_circulo

   
		mov x3, 70                        
		mov x4, 320                 	
		mov x5, 10                        
		BL dibujar_circulo

		mov x3, 60                        
		mov x4, 360                  	
		mov x5, 10                        
		BL dibujar_circulo


		mov x3, 80                        
		mov x4, 410                  	
		mov x5, 10                        
		BL dibujar_circulo

		mov x3, 90                        
		mov x4, 480                  	
		mov x5, 10                         
		BL dibujar_circulo

		mov x3, 80                        
		mov x4, 550                  	
		mov x5, 10                         
		BL dibujar_circulo


		mov x3, 60                       
		mov x4, 600                  
		mov x5, 10                        
		BL dibujar_circulo
    
	
		LDR X30, [SP, 0]					// Le asignamos x30 su posición de retorno desde el stack. (Anteriormente fue pisada al llamar calcular_pixel). 			
			ADD SP, SP, 8	
		ret


dibujar_nubes_nublado:
    SUB SP, SP, 8 						// Apuntamos en el stack.
		STUR X30, [SP, 0]
		
        // Nube
		movz w10, 0x83, lsl 16              
		movk w10, 0x8383, lsl 00
		mov x3, 60                       
		mov x4, 50                  
		mov x5, 10                        
		BL dibujar_circulo

       
		mov x3, 60                       
		mov x4, 100                 
		mov x5, 10                        
		BL dibujar_circulo

        
		mov x3, 80                       
		mov x4, 150                 
		mov x5, 10                        
		BL dibujar_circulo

       
		mov x3, 60                       
		mov x4, 210                 
		mov x5, 10                        
		BL dibujar_circulo

       
		mov x3, 30                       
		mov x4, 270                 
		mov x5, 10                        
		BL dibujar_circulo

   
		mov x3, 70                       
		mov x4, 320                 
		mov x5, 10                        
		BL dibujar_circulo

		mov x3, 60                       
		mov x4, 360                 
		mov x5, 10                        
		BL dibujar_circulo


		mov x3, 80                       
		mov x4, 410                 
		mov x5, 10                        
		BL dibujar_circulo


		mov x3, 90                       
		mov x4, 480                 
		mov x5, 10                        
		BL dibujar_circulo

		mov x3, 80                       
		mov x4, 550                 
		mov x5, 10                        
		BL dibujar_circulo


		mov x3, 60                       
		mov x4, 600                 
		mov x5, 10                        
		BL dibujar_circulo
    
	
		LDR X30, [SP, 0]					// Le asignamos x30 su posición de retorno desde el stack. (Anteriormente fue pisada al llamar calcular_pixel). 			
			ADD SP, SP, 8	
		ret


    pintar_hojas:
    SUB SP, SP, 8 						// Apuntamos en el stack.
		STUR X30, [SP, 0]

		movz w10, 0x4D, lsl 16				
		movk w10, 0xCD33, lsl 0

		mov x1, 130
		mov x2, 150
		mov x3, 450
		mov x4, 150
		BL dibujar_cuadrado


		LDR X30, [SP, 0]					// Le asignamos x30 su posición de retorno desde el stack. (Anteriormente fue pisada al llamar calcular_pixel). 			
			ADD SP, SP, 8	
		ret


    dibujar_manzanas:
        SUB SP, SP, 8 						// Apuntamos en el stack.
		STUR X30, [SP, 0]

		movz w10, 0xC8, lsl 16				
		movk w10, 0x0000, lsl 0
		mov x3, 10                        	
		mov x4, 460                  		
		mov x5, 320                         
		BL dibujar_circulo


        movz w10, 0x0A, lsl 16				
		movk w10, 0x0A0A, lsl 0
		mov x1, 2
		mov x2, 15
		mov x3, 460
		mov x4, 300
		BL dibujar_cuadrado

        movz w10, 0xC8, lsl 16				
		movk w10, 0x0000, lsl 0
		mov x3, 10                        	
		mov x4, 495                  		
		mov x5, 320                         
		BL dibujar_circulo


        movz w10, 0x0A, lsl 16				
		movk w10, 0x0A0A, lsl 0
		mov x1, 2
		mov x2, 15
		mov x3, 495
		mov x4, 300
		BL dibujar_cuadrado

        movz w10, 0xC8, lsl 16				
		movk w10, 0x0000, lsl 0
		mov x3, 10                        	
		mov x4, 550                  		
		mov x5, 320                         
		BL dibujar_circulo


        movz w10, 0x0A, lsl 16				
		movk w10, 0x0A0A, lsl 0
		mov x1, 2
		mov x2, 15
		mov x3, 550
		mov x4, 300
		BL dibujar_cuadrado

		LDR X30, [SP, 0]					// Le asignamos x30 su posición de retorno desde el stack. (Anteriormente fue pisada al llamar calcular_pixel). 			
			ADD SP, SP, 8	
		ret


	pintar_fondo:
		SUB SP, SP, 8 						// Apuntamos en el stack.
		STUR X30, [SP, 0]
		movz w10, 0x4D, lsl 16
		movk w10, 0xECFF, lsl 00
		mov x1, SCREEN_WIDTH
		mov x2, SCREEN_HEIGH
		mov x3, 0
		mov x4, 0
		BL dibujar_cuadrado

		LDR X30, [SP, 0]					// Le asignamos x30 su posición de retorno desde el stack. (Anteriormente fue pisada al llamar calcular_pixel). 			
			ADD SP, SP, 8	
		ret

