title "Proyecto: Galaga" ;codigo opcional. Descripcion breve del programa, el texto entrecomillado se imprime como cabecera en cada página de código
.model small ;directiva de modelo de memoria, small => 64KB para memoria de programa y 64KB para memoria de datos
.386 ;directiva para indicar version del procesador
.stack 128 ;Define el tamano del segmento de stack, se mide en bytes
.data ;Definicion del segmento de datos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Definición de constantes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq equ 200d ;'╚'
marcoEsqInfDer equ 188d ;'╝'
marcoEsqSupDer equ 187d ;'╗'
marcoEsqSupIzq equ 201d ;'╔'
marcoCruceVerSup equ 203d ;'╦'
marcoCruceHorDer equ 185d ;'╣'
marcoCruceVerInf equ 202d ;'╩'
marcoCruceHorIzq equ 204d ;'╠'
marcoCruce equ 206d ;'╬'
marcoHor equ 205d ;'═'
marcoVer equ 186d ;'║'
;Atributos de color de BIOS
;Valores de color para carácter
cNegro equ 00h
cAzul equ 01h
cVerde equ 02h
cCyan equ 03h
cRojo equ 04h
cMagenta equ 05h
cCafe equ 06h
cGrisClaro equ 07h
cGrisOscuro equ 08h
cAzulClaro equ 09h
cVerdeClaro equ 0Ah
cCyanClaro equ 0Bh
cRojoClaro equ 0Ch
cMagentaClaro equ 0Dh
cAmarillo equ 0Eh
cBlanco equ 0Fh
;Valores de color para fondo de carácter
bgNegro equ 00h
bgAzul equ 10h
bgVerde equ 20h
bgCyan equ 30h
bgRojo equ 40h
bgMagenta equ 50h
bgCafe equ 60h
bgGrisClaro equ 70h
bgGrisOscuro equ 80h
bgAzulClaro equ 90h
bgVerdeClaro equ 0A0h
bgCyanClaro equ 0B0h
bgRojoClaro equ 0C0h
bgMagentaClaro equ 0D0h
bgAmarillo equ 0E0h
bgBlanco equ 0F0h
;Valores para delimitar el área de juego
lim_superior equ 1
lim_inferior equ 23
lim_izquierdo equ 1
lim_derecho equ 39
;Valores de referencia para la posición inicial del jugador
ini_columna equ lim_derecho/2
ini_renglon equ 22

;Valores para la posición de los controles e indicadores dentro del juego
;Lives
lives_col equ lim_derecho+7
lives_ren equ 4

;Scores
hiscore_ren equ 11
hiscore_col equ lim_derecho+7
score_ren equ 13
score_col equ lim_derecho+7

;Botón STOP
stop_col equ lim_derecho+10
stop_ren equ 19
stop_izq equ stop_col-1
stop_der equ stop_col+1
stop_sup equ stop_ren-1
stop_inf equ stop_ren+1

;Botón PAUSE
pause_col equ stop_col+10
pause_ren equ 19
pause_izq equ pause_col-1
pause_der equ pause_col+1
pause_sup equ pause_ren-1
pause_inf equ pause_ren+1

;Botón PLAY
play_col equ pause_col+10
play_ren equ 19
play_izq equ play_col-1
play_der equ play_col+1
play_sup equ play_ren-1
play_inf equ play_ren+1


;Teclas de movimiento

Tecla_A equ 41h ;'A' para izquierda
Tecla_D equ 44h ;'D' para derecha
Tecla_SPACE equ 20h ;' ' para disparar (ASCII de Spacebar)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;////////////////////////////////////////////////////
;Definición de variables
;////////////////////////////////////////////////////
titulo db "GALAGA"
scoreStr db "SCORE"
hiscoreStr db "HI-SCORE"
livesStr db "LIVES"
blank db " "
player_lives db 3
player_score dw 0
player_hiscore dw 0

player_col db ini_columna ;posicion en columna del jugador
player_ren db ini_renglon ;posicion en renglon del jugador

enemy_col db ini_columna ;posicion en columna del enemigo
enemy_ren db 3 ;posicion en renglon del enemigo
enemy_col_min db 0 ; Límite de columna izquierda del enemigo
enemy_col_max db 0 ; Límite de columna derecha del enemigo
enemy_ren_min db 0 ; Límite de renglón superior del enemigo
enemy_ren_max db 0 ; Límite de renglón inferior del enemigo

; Variables de movimiento del enemigo
enemy_direction db 1 ; 1 = derecha, 255 (-1) = izquierda. Indica la dirección horizontal.
enemy_move_delay equ 15; Cuántos ciclos debe esperar antes de moverse (mayor = más lento).
enemy_move_timer db 0 ; Contador de tiempo para el movimiento del enemigo.

; Variables de Estado y Respawn del Enemigo
enemy_status db 0 ; 0 = Vivo/Activo, 1 = Muerto/Desaparecido (esperando respawn)
enemy_respawn_delay equ 100 ; Duración del tiempo de espera (en ciclos de juego). AUMENTADO DE 50 A 100.
enemy_respawn_timer db 0 ; Contador para el respawn

; Variables del proyectil del jugador
bullet_ren db 0 ; Posición en renglón del proyectil
bullet_col db 0 ; Posición en columna del proyectil
bullet_active db 0 ; 0 = inactivo, 1 = activo
bullet_char equ 94d ; Carácter '^' para el proyectil

; Variables de control de velocidad del proyectil (AUMENTAR bullet_speed_delay para hacerlo más LENTO)
; NOTA: La velocidad principal se controla con GAME_SPEED_DELAY
bullet_speed_timer db 0 ; Contador para la velocidad del proyectil
bullet_speed_delay equ 3 ; Cuántos ciclos debe esperar antes de moverse (mayor = más lento)

; *** CONSTANTE PRINCIPAL DE VELOCIDAD DE JUEGO ***
; Controla el framerate total del juego. AUMENTAR este valor para ralentizar todo.
GAME_SPEED_DELAY equ 25000d

col_aux db 0 ;variable auxiliar para operaciones con posicion - columna
ren_aux db 0 ;variable auxiliar para operaciones con posicion - renglon

conta db 0 ;contador

;; Variables de ayuda para lectura de tiempo del sistema
tick_ms dw 55 ;55 ms por cada tick del sistema, esta variable se usa para operación de MUL convertir ticks a segundos
mil dw 1000 ;1000 auxiliar para operación DIV entre 1000
diez dw 10 ;10 auxiliar para operaciones
sesenta db 60 ;60 auxiliar para operaciones
status db 0 ;0 stop, 1 play, 2 pause
ticks dw 0 ;Variable para almacenar el número de ticks del sistema y usarlo como referencia

;Variables que sirven de parámetros de entrada para el procedimiento IMPRIME_BOTON
boton_caracter db 0
boton_renglon db 0
boton_columna db 0
boton_color db 0
boton_bg_color db 0


;Auxiliar para calculo de coordenadas del mouse en modo Texto
ocho db 8
;Cuando el driver del mouse no está disponible
no_mouse db 'No se encuentra driver de mouse. Presione [enter] para salir$'

;////////////////////////////////////////////////////

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;Macros;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;clear - Limpia pantalla
clear macro
mov ax,0003h ;ah = 00h, selecciona modo video
;al = 03h. Modo texto, 16 colores
int 10h ;llama interrupcion 10h con opcion 00h.
;Establece modo de video limpiando pantalla
endm

;posiciona_cursor - Cambia la posición del cursor a la especificada con 'renglon' y 'columna'
posiciona_cursor macro renglon,columna
mov dh,renglon ;dh = renglon
mov dl,columna ;dl = columna
mov bx,0
mov ax,0200h ;preparar ax para interrupcion, opcion 02h
int 10h ;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm

;inicializa_ds_es - Inicializa el valor del registro DS y ES
inicializa_ds_es macro
mov ax,@data
mov ds,ax
mov es,ax ;Este registro se va a usar, junto con BP, para imprimir cadenas utilizando interrupción 10h
endm

;muestra_cursor_mouse - Establece la visibilidad del cursor del mouser
muestra_cursor_mouse macro
mov ax,1 ;opcion 0001h
int 33h ;int 33h para manejo del mouse. Opcion AX=0001h
;Habilita la visibilidad del cursor del mouse en el programa
endm

;posiciona_cursor_mouse - Establece la posición inicial del cursor del mouse
posiciona_cursor_mouse macro columna,renglon
mov dx,renglon
mov cx,columna
mov ax,4 ;opcion 0004h
int 33h ;int 33h para manejo del mouse. Opcion AX=0001h
;Habilita la visibilidad del cursor del mouse en el programa
endm

;oculta_cursor_teclado - Oculta la visibilidad del cursor del teclado
oculta_cursor_teclado macro
mov ah,01h ;Opcion 01h
mov cx,2607h ;Parametro necesario para ocultar cursor
int 10h ;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;apaga_cursor_parpadeo - Deshabilita el parpadeo del cursor cuando se imprimen caracteres con fondo de color
;Habilita 16 colores de fondo
apaga_cursor_parpadeo macro
mov ax,1003h ;Opcion 1003h
xor bl,bl ;BL = 0, parámetro para int 10h opción 1003h
  int 10h ;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'.
;Los colores disponibles están en la lista a continuacion;
; Colores:
; 0h: Negro
; 1h: Azul
; 2h: Verde
; 3h: Cyan
; 4h: Rojo
; 5h: Magenta
; 6h: Cafe
; 7h: Gris Claro
; 8h: Gris Oscuro
; 9h: Azul Claro
; Ah: Verde Claro
; Bh: Cyan Claro
; Ch: Rojo Claro
; Dh: Magenta Claro
; Eh: Amarillo
; Fh: Blanco
; utiliza int 10h opcion 09h
; 'caracter' - caracter que se va a imprimir
; 'color' - color que tomará el caracter
; 'bg_color' - color de fondo para el carácter en la celda
; Cuando se define el color del carácter, éste se hace en el registro BL:
; La parte baja de BL (los 4 bits menos significativos) define el color del carácter
; La parte alta de BL (los 4 bits más significativos) define el color de fondo "background" del carácter
imprime_caracter_color macro caracter,color,bg_color
mov ah,09h ;preparar AH para interrupcion, opcion 09h
mov al,caracter ;AL = caracter a imprimir
mov bh,0 ;BH = numero de pagina
mov bl,color
or bl,bg_color ;BL = color del caracter
;'color' define los 4 bits menos significativos
;'bg_color' define los 4 bits más significativos
mov cx,1 ;CX = numero de veces que se imprime el caracter
;CX es un argumento necesario para opcion 09h de int 10h
int 10h ;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'.
; utiliza int 10h opcion 09h
; 'cadena' - nombre de la cadena en memoria que se va a imprimir
; 'long_cadena' - longitud (en caracteres) de la cadena a imprimir
; 'color' - color que tomarán los caracteres de la cadena
; 'bg_color' - color de fondo para los caracteres en la cadena
imprime_cadena_color macro cadena,long_cadena,color,bg_color
mov ah,13h ;preparar AH para interrupcion, opcion 13h
lea bp,cadena ;BP como apuntador a la cadena a imprimir
mov bh,0 ;BH = numero de pagina
mov bl,color
or bl,bg_color ;BL = color del caracter
;'color' define los 4 bits menos significativos
;'bg_color' define los 4 bits más significativos
mov cx,long_cadena ;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
int 10h ;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;lee_mouse - Revisa el estado del mouse
;Devuelve:
;;BX - estado de los botones
;;;Si BX = 0000h, ningun boton presionado
;;;Si BX = 0001h, boton izquierdo presionado
;;;Si BX = 0002h, boton derecho presionado
;;;Si BX = 0003h, boton izquierdo y derecho presionados
; (400,120) => 80x25 =>Columna: 400 x 80 / 640 = 50; Renglon: (120 x 25 / 200) = 15 => 50,15
;;CX - columna en la que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
;;DX - renglon en el que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
lee_mouse macro
mov ax,0003h
int 33h
endm

;comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse macro
mov ax,0 ;opcion 0
int 33h ;llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm

int_teclado macro ;para entradas del teclado
mov ah,01h ;opcion 01, modifica bandera Z, si Z = 1, no hay datos en buffer de teclado. Si Z = 0, hay datos en el buffer de teclado
int 16h ;interrupcion 16h (maneja la entrada del teclado)
endm


;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;Fin Macros;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

.code
inicio: ;etiqueta inicio
inicializa_ds_es
comprueba_mouse ;macro para revisar driver de mouse
xor ax,0FFFFh ;compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
jz imprime_ui ;Si existe el driver del mouse, entonces salta a 'imprime_ui'

;Si no existe el driver del mouse entonces se muestra un mensaje
lea dx,[no_mouse]
mov ax,0900h ;opcion 9 para interrupcion 21h
int 21h ;interrupcion 21h. Imprime cadena.
jmp salir ; Sale del programa si no hay mouse driver

imprime_ui:
clear ;limpia pantalla
oculta_cursor_teclado ;oculta cursor del mouse
apaga_cursor_parpadeo ;Deshabilita parpadeo del cursor
call DIBUJA_UI ;procedimiento que dibuja marco de la interfaz
muestra_cursor_mouse ;hace visible el cursor del mouse
call IMPRIME_JUGADOR ; Dibuja la nave en la posición inicial
call IMPRIME_ENEMIGO ; Dibuja el enemigo en la posición inicial

game_loop:
; 1. Manejo del teclado (movimiento de la nave y disparo)
mov ah, 01h ; Revisa si hay una tecla disponible (no bloqueante)
int 16h
jz handle_mouse ; Si Z flag = 1 (no hay tecla), salta a revisar el mouse

; Hay una tecla disponible, la lee (bloqueante, pero ya sabemos que hay datos)
mov ah, 00h
int 16h ; AL = código ASCII, AH = scan code

call MANEJA_TECLADO ; Llama al procedimiento para mover/disparar

handle_mouse:
; 2. Manejo del mouse (solo para botones de UI como [X])
lee_mouse
conversion_mouse:
; Leer la posicion del mouse y hacer la conversion a resolucion
; 80x25 (columnas x renglones) en modo texto
mov ax,dx
div [ocho]
xor ah,ah
mov dx,ax ; DX = renglon en modo texto

mov ax,cx
div [ocho]
xor ah,ah
mov cx,ax ; CX = columna en modo texto

; Aquí se revisa si se hizo clic en el botón izquierdo
test bx,0001h
jz update_logic ; Si no hay clic, continua a la lógica de juego

; --- Se detectó un clic de mouse ---
; Lógica para revisar si se presiona [X] (Renglon 0, Columna 76-78)
cmp dx,0 ; Renglon 0
jne not_exit_button
cmp cx,76 ; Columna >= 76
jl not_exit_button
cmp cx,78 ; Columna <= 78
jle salir ; Si sí, salimos del programa

not_exit_button:
; Lógica para otros botones (STOP, PAUSE, PLAY) iría aquí

; Esperar a que se suelte el botón del mouse (para evitar doble-clic)
mouse_wait_release:
lee_mouse
test bx,0001h
jnz mouse_wait_release

update_logic:
; 3. Lógica del juego (movimiento del proyectil y colisiones)
call MUEVE_PROYECTIL
; >>> Lógica: Manejo del Estado y Movimiento del Enemigo <<<
call MANEJA_ENEMIGO

; *** NUEVO: Retardo para limitar la velocidad del bucle principal ***
call DELAY_LOOP

jmp game_loop


salir: ;inicia etiqueta salir
clear ;limpia pantalla
mov ax,4C00h ;AH = 4Ch, opción para terminar programa, AL = 0 Exit Code
int 21h ;señal 21h de interrupción, pasa el control al sistema operativo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;PROCEDIMIENTOS;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;----------------------------------------------------
; PROCEDIMIENTO: MANEJA_ENEMIGO (Actualizado para Respawn)
; Maneja el estado (vivo/muerto) y el movimiento del enemigo
;----------------------------------------------------
MANEJA_ENEMIGO proc
    push ax
    push bx
    push cx

    cmp [enemy_status], 0 ; ¿Está el enemigo vivo/activo?
    je enemy_is_active ; Si sí, salta a moverlo

    ; --- Lógica de Respawn (Si enemy_status == 1) ---
    inc [enemy_respawn_timer] ; Incrementar contador de espera
    mov al, [enemy_respawn_timer]
    cmp al, enemy_respawn_delay ; ¿Se ha alcanzado el tiempo de espera?
    jl end_maneja_enemigo ; Si no, seguir esperando

    ; Si el tiempo de espera ha terminado: Reiniciar estado y posición
    mov [enemy_status], 0 ; 0 = Activo
    mov [enemy_respawn_timer], 0 ; Resetear timer

    ; Restablecer posición y dirección inicial
    mov al, ini_columna
    mov [enemy_col], al
    mov al, 3
    mov [enemy_ren], al
    mov [enemy_direction], 1 ; Dirección inicial a la derecha

    ; Imprimir enemigo al reaparecer
    call IMPRIME_ENEMIGO

    jmp end_maneja_enemigo

enemy_is_active:
    ; --- Lógica de Movimiento (Si enemy_status == 0) ---
    ; Control de Velocidad
    inc [enemy_move_timer]
    mov al, [enemy_move_timer]
    cmp al, enemy_move_delay
    jl end_maneja_enemigo ; No mover si el timer no ha llegado al delay

    mov [enemy_move_timer], 0 ; Reiniciar timer

    ; 1. Borrar Enemigo de posición actual
    call BORRA_ENEMIGO

    ; 2. Calcular nueva posición horizontal
    mov al, [enemy_col]
    mov bl, [enemy_direction]
    add al, bl
    mov [enemy_col], al

    ; 3. Comprobar límites y cambiar dirección/bajar

    ; Límite DERECHO: Si la columna central (enemy_col) es mayor o igual a (lim_derecho - 2)
    mov al, [enemy_col]
    cmp al, lim_derecho - 2
    jg reached_right

    ; Límite IZQUIERDO: Si la columna central (enemy_col) es menor o igual a (lim_izquierdo + 2)
    mov al, [enemy_col]
    cmp al, lim_izquierdo + 2
    jl reached_left

    jmp continue_draw

reached_right:
    ; 3a. Invertir dirección (de 1 a -1/255)
    mov [enemy_direction], 255d ; -1 (Izquierda)
    ; Forzar a la columna límite
    mov al, lim_derecho - 2
    mov [enemy_col], al

    ; 3b. Mover hacia abajo
    inc [enemy_ren]
    jmp check_game_over

reached_left:
    ; 3a. Invertir dirección (de -1/255 a 1)
    mov [enemy_direction], 1 ; 1 (Derecha)
    ; Forzar a la columna límite
    mov al, lim_izquierdo + 2
    mov [enemy_col], al

    ; 3b. Mover hacia abajo
    inc [enemy_ren]
    jmp check_game_over

check_game_over:
    ; Comprobar si el enemigo ha llegado al límite inferior
    mov al, [enemy_ren]
    cmp al, lim_inferior - 2 ; Límite inferior del área de juego
    jge handle_game_over

    jmp continue_draw

handle_game_over:
    ; Simplemente forzaremos a mantenerse en el límite
    mov al, lim_inferior - 2
    mov [enemy_ren], al

continue_draw:
    ; 4. Dibujar enemigo en la nueva posición
    call IMPRIME_ENEMIGO

end_maneja_enemigo:
    pop cx
    pop bx
    pop ax
    ret
MANEJA_ENEMIGO endp


;----------------------------------------------------
; NUEVO PROCEDIMIENTO: DELAY_LOOP
; Implementa un retardo forzado (busy-wait)
;----------------------------------------------------
DELAY_LOOP proc
    push cx
    ; CX es el contador, el valor se toma de GAME_SPEED_DELAY
    mov cx, GAME_SPEED_DELAY
delay_start:
    loop delay_start
    pop cx
    ret
DELAY_LOOP endp

;----------------------------------------------------
; PROCEDIMIENTO: LANZA_PROYECTIL
; Inicializa la posición del proyectil y lo activa
;----------------------------------------------------
LANZA_PROYECTIL proc
push ax
; Si el proyectil ya está activo, ignorar el nuevo disparo
cmp [bullet_active], 1
je end_lanza_proyectil

; Activar proyectil
mov [bullet_active], 1

; Poner el proyectil justo encima del cañón del jugador
mov al, [player_col]
mov [bullet_col], al
; La nave tiene 3 renglones de altura. El proyectil inicia en player_ren - 3.
mov al, [player_ren]
sub al, 3
mov [bullet_ren], al

end_lanza_proyectil:
pop ax
ret
LANZA_PROYECTIL endp

;----------------------------------------------------
; PROCEDIMIENTO: RESETEA_PROYECTIL (CORREGIDO)
; Desactiva el proyectil y lo borra de la pantalla
;----------------------------------------------------
RESETEA_PROYECTIL proc
push ax
push bx
push dx

; 1. Borrar el proyectil de su posición actual
; Solo borrar si el renglón es mayor o igual a 1 (área de juego)
mov al, [bullet_ren]
cmp al, lim_superior
jl skip_borrado_proyectil ; Si renglón < 1 (es 0 o menos), no intentar borrar

mov al, [bullet_col]
mov [col_aux], al
mov al, [bullet_ren]
mov [ren_aux], al
call BORRA_PROYECTIL

skip_borrado_proyectil:
; 2. Desactivar el proyectil
mov [bullet_active], 0
; Asegurar que el temporizador de velocidad también se reinicie
mov [bullet_speed_timer], 0
pop dx
pop bx
pop ax
ret
RESETEA_PROYECTIL endp

;----------------------------------------------------
; PROCEDIMIENTO: MUEVE_PROYECTIL
; Mueve el proyectil y comprueba las condiciones de finalización
;----------------------------------------------------
MUEVE_PROYECTIL proc
push ax
push bx
push cx

; Si no está activo, salir
cmp [bullet_active], 0
je end_mueve_proyectil

; --- Control de Velocidad (Speed Timer) ---
; Este timer ahora actúa como un multiplicador para el retardo general del juego
inc [bullet_speed_timer]
mov al, [bullet_speed_timer]
cmp al, bullet_speed_delay
jl end_mueve_proyectil ; Si el contador no ha llegado al delay, salta (no se mueve)

; Reiniciar el contador de velocidad y continuar el movimiento
mov [bullet_speed_timer], 0

; 1. Borrar el proyectil en su posición anterior
call BORRA_PROYECTIL

; 2. Mover el proyectil
dec [bullet_ren]

; 3. Comprobar colisiones
call COMPRUEBA_COLISION

; Si el proyectil sigue activo después de la comprobación, lo dibuja en la nueva posición
cmp [bullet_active], 1
je draw_bullet
jmp end_mueve_proyectil ; Si fue desactivado (colisión), no dibujarlo

draw_bullet:
call IMPRIME_PROYECTIL

end_mueve_proyectil:
pop cx
pop bx
pop ax
ret
MUEVE_PROYECTIL endp

;----------------------------------------------------
; PROCEDIMIENTO: COMPRUEBA_COLISION (ACTUALIZADO para Respawn)
; Verifica si el proyectil toca el borde superior o al enemigo
;----------------------------------------------------
COMPRUEBA_COLISION proc
push ax
push bx
push cx
push dx

; Si el enemigo no está activo, no hay colisión posible
cmp [enemy_status], 1
je check_boundary_only ; Si enemigo está muerto, solo revisar el límite superior

; --- Chequeo de Colisión con Enemigo (Estructura de 3x5) ---

; 1. Chequeo de Renglón
mov al, [bullet_ren]
cmp al, [enemy_ren]
jl check_boundary_only ; Si renglón es muy alto, ir a chequear borde
mov bl, [enemy_ren]
add bl, 2
cmp al, bl
jg check_boundary_only ; Si renglón es muy bajo, ir a chequear borde

; 2. Chequeo de Columna (Solo si el renglón es correcto)
mov al, [bullet_col]
mov bl, [enemy_col]
sub bl, 2
cmp al, bl
jl check_boundary_only
mov bl, [enemy_col]
add bl, 2
cmp al, bl
jle hit_enemy ; ¡Colisión!

check_boundary_only:
; --- Chequeo de Borde Superior ---
; Si el proyectil se movió al renglón lim_superior (1) o menor (0)
mov al, [bullet_ren]
cmp al, lim_superior
jle hit_boundary ; Si renglón <= límite superior, colisión con borde

jmp end_collision_check

hit_boundary:
; Si golpea el límite superior, desactiva el proyectil
call RESETEA_PROYECTIL
jmp end_collision_check

hit_enemy:
; Si golpea al enemigo, desactiva el proyectil
call RESETEA_PROYECTIL

; --- Desactivar Enemigo y Borrar ---
call BORRA_ENEMIGO ; Borrar el gráfico del enemigo inmediatamente
mov [enemy_status], 1 ; Poner el enemigo en estado "muerto/espera"
mov [enemy_respawn_timer], 0 ; Reiniciar contador de respawn

inc word ptr [player_score] ; Sumar 1 punto
call IMPRIME_SCORE ; Actualizar score

end_collision_check:
pop dx
pop cx
pop bx
pop ax
ret
COMPRUEBA_COLISION endp

;----------------------------------------------------
; PROCEDIMIENTOS: IMPRIME_PROYECTIL / BORRA_PROYECTIL
;----------------------------------------------------
IMPRIME_PROYECTIL proc
push ax
; Caracter '^' (94d) con color Rojo Claro
posiciona_cursor [bullet_ren],[bullet_col]
imprime_caracter_color bullet_char,cBlanco,bgNegro
pop ax
ret
IMPRIME_PROYECTIL endp

BORRA_PROYECTIL proc
push ax
; --- MODIFICACIÓN CLAVE PARA PROTEGER EL MARCO ---
; Si el renglón es 0 o 24 (donde está el marco), no borramos.
; El proyectil solo debe borrarse si está dentro del área de juego [1, 23].
mov al, [bullet_ren]
cmp al, lim_superior
jl end_borra ; Si renglón < 1 (es 0 o menos), no borrar

cmp al, lim_inferior
jg end_borra ; Si renglón > 23 (es 24 o más), no borrar

; Si está en el área [1, 23], borrar con un espacio negro
posiciona_cursor [bullet_ren],[bullet_col]
imprime_caracter_color 32d,cNegro,bgNegro

end_borra:
pop ax
ret
BORRA_PROYECTIL endp


;----------------------------------------------------
; PROCEDIMIENTO: MANEJA_TECLADO (Modificado para Disparo)
; Mueve la nave del jugador si se presiona 'A' o 'D', o dispara con ' '
;----------------------------------------------------
MANEJA_TECLADO proc
push ax
push bx
push cx
; Guardar AL, ya que se modificará
push ax
; Convertir a mayúscula para simplificar la comprobación
cmp al,'a'
jl check_d_key ; Si ya es mayúscula o no es alfabético, saltar
cmp al,'z'
jg check_d_key
sub al, 20h ; Convierte a mayúscula ('a' -> 'A', 'd' -> 'D')

check_d_key:
; Comprobar 'D' (Derecha)
cmp al,Tecla_D
jne check_a_key
; Lógica Mover Derecha
mov bl,[player_col]
cmp bl,lim_derecho - 2
jge check_fire_key ; No moverse si está en el límite

call BORRA_JUGADOR
inc [player_col]
call IMPRIME_JUGADOR
jmp check_fire_key

check_a_key:
; Comprobar 'A' (Izquierda)
cmp al,Tecla_A
jne check_fire_key
; Lógica Mover Izquierda
mov bl,[player_col]
cmp bl,lim_izquierdo + 2
jle check_fire_key ; No moverse si está en el límite

call BORRA_JUGADOR
dec [player_col]
call IMPRIME_JUGADOR
jmp check_fire_key

check_fire_key:
; Restaurar AL original (código ASCII)
pop ax
; Comprobar Spacebar (Disparo)
cmp al, Tecla_SPACE
jne end_maneja_teclado

; Lógica Disparo
call LANZA_PROYECTIL

end_maneja_teclado:
pop cx
pop bx
pop ax
ret
MANEJA_TECLADO endp

DIBUJA_UI proc
;imprimir esquina superior izquierda del marco
posiciona_cursor 0,0
imprime_caracter_color marcoEsqSupIzq,cAmarillo,bgNegro
;imprimir esquina superior derecha del marco
posiciona_cursor 0,79
imprime_caracter_color marcoEsqSupDer,cAmarillo,bgNegro
;imprimir esquina inferior izquierda del marco
posiciona_cursor 24,0
imprime_caracter_color marcoEsqInfIzq,cAmarillo,bgNegro
;imprimir esquina inferior derecha del marco
posiciona_cursor 24,79
imprime_caracter_color marcoEsqInfDer,cAmarillo,bgNegro
;imprimir marcos horizontales, superior e inferior
mov cx,78 ;CX = 004Eh => CH = 00h, CL = 4Eh 
marcos_horizontales:
mov [col_aux],cl
;Superior
posiciona_cursor 0,[col_aux]
imprime_caracter_color marcoHor,cAmarillo,bgNegro
;Inferior
posiciona_cursor 24,[col_aux]
imprime_caracter_color marcoHor,cAmarillo,bgNegro
mov cl,[col_aux]
loop marcos_horizontales

;imprimir marcos verticales, derecho e izquierdo
mov cx,23 ;CX = 0017h => CH = 00h, CL = 17h 
marcos_verticales:
mov [ren_aux],cl
;Izquierdo
posiciona_cursor [ren_aux],0
imprime_caracter_color marcoVer,cAmarillo,bgNegro
;Inferior
posiciona_cursor [ren_aux],79
imprime_caracter_color marcoVer,cAmarillo,bgNegro
;Limite mouse
posiciona_cursor [ren_aux],lim_derecho+1
imprime_caracter_color marcoVer,cAmarillo,bgNegro

mov cl,[ren_aux]
loop marcos_verticales

;imprimir marcos horizontales internos
mov cx,79-lim_derecho-1
marcos_horizontales_internos:
push cx
mov [col_aux],cl
add [col_aux],lim_derecho
;Interno superior 
posiciona_cursor 8,[col_aux]
imprime_caracter_color marcoHor,cAmarillo,bgNegro

;Interno inferior
posiciona_cursor 16,[col_aux]
imprime_caracter_color marcoHor,cAmarillo,bgNegro

mov cl,[col_aux]
pop cx
loop marcos_horizontales_internos

;imprime intersecciones internas
posiciona_cursor 0,lim_derecho+1
imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
posiciona_cursor 24,lim_derecho+1
imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

posiciona_cursor 8,lim_derecho+1
imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
posiciona_cursor 8,79
imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

posiciona_cursor 16,lim_derecho+1
imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
posiciona_cursor 16,79
imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

;imprimir [X] para cerrar programa
posiciona_cursor 0,76
imprime_caracter_color '[',cAmarillo,bgNegro
posiciona_cursor 0,77
imprime_caracter_color 'X',cRojoClaro,bgNegro
posiciona_cursor 0,78
imprime_caracter_color ']',cAmarillo,bgNegro

;imprimir título
posiciona_cursor 0,37
imprime_cadena_color [titulo],6,cAmarillo,bgNegro

call IMPRIME_TEXTOS

call IMPRIME_BOTONES

call IMPRIME_DATOS_INICIALES

call IMPRIME_SCORES

call IMPRIME_LIVES

ret
endp

IMPRIME_TEXTOS proc
;Imprime cadena "LIVES"
posiciona_cursor lives_ren,lives_col
imprime_cadena_color livesStr,5,cGrisClaro,bgNegro

;Imprime cadena "SCORE"
posiciona_cursor score_ren,score_col
imprime_cadena_color scoreStr,5,cGrisClaro,bgNegro

;Imprime cadena "HI-SCORE"
posiciona_cursor hiscore_ren,hiscore_col
imprime_cadena_color hiscoreStr,8,cGrisClaro,bgNegro
ret
endp

IMPRIME_BOTONES proc
;Botón STOP
mov [boton_caracter],254d ;Carácter '■'
mov [boton_color],bgAmarillo ;Background amarillo
mov [boton_renglon],stop_ren ;Renglón en "stop_ren"
mov [boton_columna],stop_col ;Columna en "stop_col"
call IMPRIME_BOTON ;Procedimiento para imprimir el botón
;Botón PAUSE
mov [boton_caracter],19d ;Carácter '‼'
mov [boton_color],bgAmarillo ;Background amarillo
mov [boton_renglon],pause_ren ;Renglón en "pause_ren"
mov [boton_columna],pause_col ;Columna en "pause_col"
call IMPRIME_BOTON ;Procedimiento para imprimir el botón
;Botón PLAY
mov [boton_caracter],16d ;Carácter '►'
mov [boton_color],bgAmarillo ;Background amarillo
mov [boton_renglon],play_ren ;Renglón en "play_ren"
mov [boton_columna],play_col ;Columna en "play_col"
call IMPRIME_BOTON ;Procedimiento para imprimir el botón
ret
endp

IMPRIME_SCORES proc
;Imprime el valor de la variable player_score en una posición definida
call IMPRIME_SCORE
;Imprime el valor de la variable player_hiscore en una posición definida
call IMPRIME_HISCORE
ret
endp

IMPRIME_SCORE proc
;Imprime "player_score" en la posición relativa a 'score_ren' y 'score_col'
mov [ren_aux],score_ren
mov [col_aux],score_col+20
mov bx,[player_score]
call IMPRIME_BX
ret
endp

IMPRIME_HISCORE proc
;Imprime "player_score" en la posición relativa a 'hiscore_ren' y 'hiscore_col'
mov [ren_aux],hiscore_ren
mov [col_aux],hiscore_col+20
mov bx,[player_hiscore]
call IMPRIME_BX
ret
endp

;BORRA_SCORES borra los marcadores numéricos de pantalla sustituyendo la cadena de números por espacios
BORRA_SCORES proc
call BORRA_SCORE
call BORRA_HISCORE
ret
endp

BORRA_SCORE proc
posiciona_cursor score_ren,score_col+20 ;posiciona el cursor relativo a score_ren y score_col
imprime_cadena_color blank,5,cBlanco,bgNegro ;imprime cadena blank (espacios) para "borrar" lo que está en pantalla
ret
endp

BORRA_HISCORE proc
posiciona_cursor hiscore_ren,hiscore_col+20 ;posiciona el cursor relativo a hiscore_ren y hiscore_col
imprime_cadena_color blank,5,cBlanco,bgNegro ;imprime cadena blank (espacios) para "borrar" lo que está en pantalla
ret
endp

;Imprime el valor del registro BX como entero sin signo (positivo)
;Se imprime con 5 dígitos (incluyendo ceros a la izquierda)
;Se usan divisiones entre 10 para obtener dígito por dígito en un LOOP 5 veces (una por cada dígito)
IMPRIME_BX proc
mov ax,bx
mov cx,5
div10:
xor dx,dx
div [diez]
push dx
loop div10
mov cx,5
imprime_digito:
mov [conta],cl
posiciona_cursor [ren_aux],[col_aux]
pop dx
or dl,30h
imprime_caracter_color dl,cBlanco,bgNegro
xor ch,ch
mov cl,[conta]
inc [col_aux]
loop imprime_digito
ret
endp

IMPRIME_DATOS_INICIALES proc
call DATOS_INICIALES ;inicializa variables de juego
;inicializa el estado del proyectil
mov [bullet_active], 0
;imprime la 'nave' del jugador
;borra la posición actual, luego se reinicia la posición y entonces se vuelve a imprimir
call BORRA_JUGADOR
mov [player_col], ini_columna
mov [player_ren], ini_renglon
;Imprime jugador
call IMPRIME_JUGADOR

;Borrar posicion actual del enemigo y reiniciar su posicion
call BORRA_ENEMIGO
mov [enemy_col], ini_columna
mov [enemy_ren], 3
mov [enemy_direction], 1 ; Reiniciar dirección a Derecha
mov [enemy_status], 0 ; Asegurar que empieza visible
mov [enemy_respawn_timer], 0

;Imprime enemigo
call IMPRIME_ENEMIGO

ret
endp

;Inicializa variables del juego
DATOS_INICIALES proc
mov [player_score],0
mov [player_lives], 3
ret
endp

;Imprime los caracteres ☻ que representan vidas. Inicialmente se imprime el número de 'player_lives'
IMPRIME_LIVES proc
xor cx,cx
mov di,lives_col+20
mov cl,[player_lives]
imprime_live:
push cx
mov ax,di
posiciona_cursor lives_ren,al
imprime_caracter_color 2d,cCyanClaro,bgNegro
add di,2
pop cx
loop imprime_live
ret
endp

;Imprime la nave del jugador, que recibe como parámetros las variables ren_aux y col_aux, que indican la posición central inferior
PRINT_PLAYER proc
; Guarda registros usados
push ax
push bx
push cx
push dx

; AL - caracter (219), BL - color (cBlanco | bgNegro), CX - cuenta (1)

; Start at the bottom center position (player_ren, player_col)
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
add [ren_aux],2
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
inc [ren_aux]
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
add [col_aux],3
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro
inc [ren_aux]
inc [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 219,cBlanco,bgNegro

; Restaura el valor de ren_aux/col_aux para que refleje la posición central
; La posición central es player_ren (bottom row) y player_col (center column)
mov al,[player_col]
mov ah,[player_ren]
mov [col_aux],al
mov [ren_aux],ah

pop dx
pop cx
pop bx
pop ax
ret
endp

;Borra la nave del jugador dibujando espacios negros en su posición.
DELETE_PLAYER proc
; Guarda registros usados
push ax
push bx
push cx
push dx
; Caracter: Espacio (32d), Color: Negro (cNegro), Fondo: Negro (bgNegro)
; Esto asegura que se borra el pixel
; Start at the bottom center position (player_ren, player_col)
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
add [ren_aux],2
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
inc [ren_aux]
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
add [col_aux],3
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
inc [ren_aux]
inc [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro

; Restaura el valor de ren_aux/col_aux para que refleje la posición central
mov al,[player_col]
mov ah,[player_ren]
mov [col_aux],al
mov [ren_aux],ah

pop dx
pop cx
pop bx
pop ax
ret
endp

;Imprime la nave del enemigo
PRINT_ENEMY proc
; Guarda registros usados
push ax
push bx
push cx
push dx

; Las coordenadas ren_aux y col_aux contienen enemy_ren y enemy_col (el centro)

posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
sub [ren_aux],2
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
dec [ren_aux]
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
add [col_aux],3
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro
dec [ren_aux]
inc [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 178,cRojo,bgNegro

; Restaura el valor de ren_aux/col_aux para que refleje la posición central
mov al,[enemy_col]
mov ah,[enemy_ren]
mov [col_aux],al
mov [ren_aux],ah
pop dx
pop cx
pop bx
pop ax
ret
endp

;Borra la nave del enemigo
DELETE_ENEMY proc
; Guarda registros usados
push ax
push bx
push cx
push dx

; Usa el mismo patrón de dibujo pero con espacio y fondo negro para borrar
; Asume que ren_aux y col_aux ya están cargados con enemy_ren/enemy_col
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
sub [ren_aux],2
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
dec [ren_aux]
dec [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
add [col_aux],3
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
inc [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro
dec [ren_aux]
inc [col_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color 32d,cNegro,bgNegro

; Restaura el valor de ren_aux/col_aux para que refleje la posición central
mov al,[enemy_col]
mov ah,[enemy_ren]
mov [col_aux],al
mov [ren_aux],ah
pop dx
pop cx
pop bx
pop ax
ret
endp

;procedimiento IMPRIME_BOTON
;Dibuja un boton que abarca 3 renglones y 5 columnas
;con un caracter centrado dentro del boton
;en la posición que se especifique (esquina superior izquierda)
;y de un color especificado
;Utiliza paso de parametros por variables globales
;Las variables utilizadas son:
;boton_caracter: debe contener el caracter que va a mostrar el boton
;boton_renglon: contiene la posicion del renglon en donde inicia el boton
;boton_columna: contiene la posicion de la columna en donde inicia el boton
;boton_color: contiene el color del boton
IMPRIME_BOTON proc
;background de botón
mov ax,0600h ;AH=06h (scroll up window) AL=00h (borrar)
mov bh,cRojo ;Caracteres en color amarillo
xor bh,[boton_color]
mov ch,[boton_renglon]
mov cl,[boton_columna]
mov dh,ch
add dh,2
mov dl,cl
add dl,2
int 10h
mov [col_aux],dl
mov [ren_aux],dh
dec [col_aux]
dec [ren_aux]
posiciona_cursor [ren_aux],[col_aux]
imprime_caracter_color [boton_caracter],cRojo,[boton_color]
ret ;Regreso de llamada a procedimiento
endp ;Indica fin de procedimiento UI para el ensamblador

BORRA_JUGADOR proc
mov al,[player_col]
mov ah,[player_ren]
mov [col_aux],al
mov [ren_aux],ah
call DELETE_PLAYER
ret
endp

IMPRIME_JUGADOR proc
mov al,[player_col]
mov ah,[player_ren]
mov [col_aux],al
mov [ren_aux],ah
call PRINT_PLAYER
ret
endp

IMPRIME_ENEMIGO proc
; Solo dibujar si el enemigo está activo (status 0)
cmp [enemy_status], 0
jne end_imprime_enemigo

mov al,[enemy_col]
mov ah,[enemy_ren]
mov [col_aux],al
mov [ren_aux],ah
call PRINT_ENEMY

end_imprime_enemigo:
ret
endp

BORRA_ENEMIGO proc
mov al,[enemy_col]
mov ah,[enemy_ren]
mov [col_aux],al
mov [ren_aux],ah
call DELETE_ENEMY
ret
endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;FIN PROCEDIMIENTOS;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end inicio ;fin de etiqueta inicio