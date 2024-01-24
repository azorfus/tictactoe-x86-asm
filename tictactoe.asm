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
	mov rbx, 14
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

	lea rax, [invalid_error]
	mov rbx, inv_error_len
	call print

	pop rbx
	pop rax
	retn

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
		jl invalid_inp
		
		cmp byte[usrinp], 0x39
		jg invalid_inp
	
	jmp .game_loop
	.exit:
	mov rax, 0x1 ; syscall code for exit: 1
	mov rbx, 0 ; exitting with return value 0
	int 0x80

section .data:
	welcome: db "Welcome to tic-tac-toe! First player to start gets X", 0xA
	welcome_len equ $-welcome

	prompt: db 0xA, "|1|2|3|", 0xA, "|4|5|6|", 0xA, "|7|8|9|", 0xA, "Player's choice? (1 - 9) [0: Exit] > "
	prompt_len equ $-prompt

	invalid_error: db "Invalid Input, Try again!!!", 0xA
	inv_error_len equ $-invalid_error

	error: db "Tile already occupied!!!", 0xA
	error_len equ $-error

	won1: db "Player 1 won!!!", 0xA
	won2: db "Player 2 won!!!", 0xA
	won_len equ $-won1
