; Calling print three times per board print seemed innefficient.
; the other idea is to call it once and use a big single buffer
; for the entire board, But computational overhead while manipulating
; a comparitively larger buffer might cause more performace issues???

section .bss
	slot resb 9 ; holds the slot values of the board, i.e. X or O or _
	buff resb 8 ; row buffer
	usrinp resb 8 ; user input buffer

section .text
global _start

print: ; ssize_t write(file_descriptor, buffer, buffer_size)
	mov rcx, rax ; buffer
	mov rdx, rbx ; buffer_size
	
	push rax
	push rbx

	mov rax, 0x4 ; syscall number 4 for write
	mov rbx, 0x1 ; file descriptor for stdout
	int 0x80 ; interrupt number for calling the kernel (checks rax)

	pop rbx
	pop rax
	retn

; Board example:
; |X|X|X|
; |O|O|O|
; |_|_|_|

print_row:
	push rax

	mov rcx, 0
	.print_cell: ; buff + (1 + 2*rcx)
		mov rdx, 1
		imul r8, rcx, 0x2
		add rdx, r8

		mov al, byte[slot + r10] ; why the need of two such instructions?
		mov byte[buff + rdx], al ; why not: mov byte[buff + rdx], byte[slot + rbx]

		add rcx, 0x1
		add r10, 0x1

	cmp rcx, 0x2
	jle .print_cell
	
	lea rax, [buff]
	mov rbx, 8
	call print
	
	pop rax
	retn

print_board:
	push rax
	push rbx
	push rcx
	push rdx

	mov r9, 0
	mov r10, 0
	.call_row: ; a simple loop to call print_row three times
		call print_row
		add r9, 0x1

	cmp r9, 0x2
	jle .call_row

	pop rdx
	pop rcx
	pop rbx
	pop rax
	retn

input:
	mov rcx, rax
	mov rdx, rbx
	mov rax, 3
	mov rbx, 0x0
	int 0x80
	retn

ask:
	push rax
	push rbx

	lea rax, [prompt]
	mov rbx, prompt_len
	call print

	pop rbx
	pop rax
	retn

invalid_inp:
	push rax
	push rbx


	pop rbx
	pop rax
	retn

stoi:
	push rbx

	xor ebx, ebx
	sub al, '0'
	imul ebx, 10
	add ebx, eax
	mov eax, ebx

	pop rbx
	retn

check_routine:
	cmp bl, cl
	jne .no_match

	cmp cl, dl
	jne .no_match

	cmp dl, 'X'
	je .x_match

	cmp dl, 'O'
	je .o_match
	
	.no_match:
		mov r8, 0
		jmp .exit_3
	
	.x_match:
		mov r8, 1
		jmp .exit_3

	.o_match:
		mov r8, 2

	.exit_3:
	retn

check_win:
	push rax
	push rbx
	push rcx
	push rdx

	mov r8, 0
	
	; Rows

	mov bl, byte[slot]
	mov cl, byte[slot + 1]
	mov dl, byte[slot + 2]
	call check_routine
	cmp r8, 0
	jne .done

	mov bl, byte[slot + 3]
	mov cl, byte[slot + 4]
	mov dl, byte[slot + 5]
	call check_routine
	cmp r8, 0
	jne .done

	mov bl, byte[slot + 6]
	mov cl, byte[slot + 7]
	mov dl, byte[slot + 8]
	call check_routine
	cmp r8, 0
	jne .done

	; Columns

	mov bl, byte[slot]
	mov cl, byte[slot + 3]
	mov dl, byte[slot + 6]
	call check_routine
	cmp r8, 0
	jne .done

	mov bl, byte[slot + 1]
	mov cl, byte[slot + 4]
	mov dl, byte[slot + 7]
	call check_routine
	cmp r8, 0
	jne .done

	mov bl, byte[slot + 2]
	mov cl, byte[slot + 5]
	mov dl, byte[slot + 8]
	call check_routine
	cmp r8, 0
	jne .done

	; Diagonals

	mov bl, byte[slot]
	mov cl, byte[slot + 4]
	mov dl, byte[slot + 8]
	call check_routine
	cmp r8, 0
	jne .done

	mov bl, byte[slot + 2]
	mov cl, byte[slot + 4]
	mov dl, byte[slot + 6]
	call check_routine
	cmp r8, 0
	jne .done

	.done:
		; exit routine

	pop rdx
	pop rcx
	pop rbx
	pop rax
	retn ; retn result in r8

_start:
	mov rdi, slot ; rdi = destination pointer for buffer
	mov al, 0x5f ; '_' = 0x5f
	mov rcx, 9
	rep stosb ; repeats stosb 9 times (rcx value)
			  ; i.e. we're filling up '_' in the buffer

	mov byte[buff], 0x7c ; '|' = 0x7c
	mov byte[buff + 2], 0x7c
	mov byte[buff + 4], 0x7c
	mov byte[buff + 6], 0x7c
	mov byte[buff + 7], 0xA
	xor r11, r11 ; this register will be used to hold 0 or 1, i.e X or O's turn
	mov r11, 0

	.game_loop:
		
		call print_board

		call ask
		lea rax, [usrinp]
		mov rbx, 8
		call input
		
		cmp byte[usrinp], 0x30
		je .exit
		
		; Checking input
		cmp byte[usrinp], 0x30
		jl .inval ; instead of calling, we're jumping. RIP is not stored anywhere
		
		cmp byte[usrinp], 0x39
		jg .inval

		mov al, byte[usrinp]
		call stoi
		
		sub eax, 0x1
		cmp byte[slot + eax], '_'
		jne .inval_override

		; checking whether 0, if zero then slip if not then jump
		; no need for complicated comparisions since r11 is internal variable
		; no need to check for other values.
		test r11, r11
		jnz .o_turn

		mov byte[slot + eax], 'X'
		jmp .cheeky_jump

		.o_turn:
			mov byte[slot + eax], 'O'

		.cheeky_jump:

		test r8, r8
		call check_win
		
		cmp r8, 1
		je .won_x

		cmp r8, 2
		je .won_o

		xor r11, 1 ; toggles 0 and 1
		jmp .game_loop
		
		.inval:
			lea rax, [invalid_error]
			mov rbx, inv_error_len
			call print
			jmp .cheeky_jump2

		.inval_override:
			lea rax, [error]
			mov rbx, error_len
			call print

		.cheeky_jump2:
			
	jmp .game_loop

	.won_x:
		lea rax, [won1]
		mov rbx, won1_len
		call print
		jmp .exit

	.won_o:
		lea rax, [won2]
		mov rbx, won2_len
		call print

	.exit:
		mov rax, 0x1 ; syscall code for exit: 1
		mov rbx, 0 ; exitting with return value 0
		int 0x80

section .data:
	welcome: db "Welcome to tic-tac-toe! First player to start gets X", 0xA
	welcome_len equ $-welcome

	prompt: db 0xA, "|1|2|3|", 0xA, "|4|5|6|", 0xA, "|7|8|9|", 0xA, "Player's choice? (1 - 9) [0: Exit] > "
	prompt_len equ $-prompt

	invalid_error: db 0xA, "Invalid Input, Try again!!!", 0xA
	inv_error_len equ $-invalid_error

	error: db 0xA, "Tile already occupied!!!", 0xA
	error_len equ $-error

	won1: db 0xA, "Player 1 won!!!", 0xA
	won1_len equ $-won1
	won2: db 0xA, "Player 2 won!!!", 0xA
	won2_len equ $-won2
