section .text 
  global itoa64
  global print 
  global strlen 
  global strcmp

itoa64:

  push rbp 
  mov rbp,rsp 
  sub rsp,48
  push rbx 
  push r12

  mov rbx,rdi ; number
  mov r12,rsi ; buffer addr 

  cmp rdi,0 
  jne .L01

  mov byte [r12],'0'
  mov byte [r12 + 1],0 

  pop r12 
  pop rbx 

  mov rax,1 
  leave 
  ret 

.L01:
 
  push r14 

  xor r14,r14 ; neg 

  cmp rdi,0 
  sets al

  movzx r14,al 

  ; unsigned rax  
  mov rax,rdi 

  test r14,r14 
  jz .not_neg 

  neg rax 

.not_neg:

  mov qword [rbp - 32],0
  xor rcx,rcx

.L02:

  cmp rax,0 
  je .L03 

  xor rdx,rdx 
  mov rbx,10 

  div rbx ; rax % rbx(10)
  add dl,'0'

  mov byte [rbp - 32 + rcx],dl
  inc rcx 

  jmp .L02 ; break loop 

.L03:

  xor rbx,rbx ; len = 0 
  test r14,r14 
  jz .reverse_byte 

  mov byte [r12],'-'
  inc rbx 

.reverse_byte:

  dec rcx 

.reverse_iter:

  movzx rax,byte [rbp - 32 + rcx]
  mov byte [r12 + rbx],al 
  inc rbx 
  dec rcx
  jns .reverse_iter 

  mov byte [r12 + rbx],0 
  mov rax,rbx 

  pop r14 
  pop r12 
  pop rbx 

  leave
  ret 

strlen:

  push rcx
  xor rcx,rcx ; unsigned 

.L01:

  cmp byte [rcx + rdi],0 
  je .L02 
  add rcx,1 
  setc dl 
  test dl,dl 
  jnz .L03 
  jmp .L01 

.L02:

  mov rax,rcx 
  pop rcx 
  ret 

.L03:

  ud2 

print:

  push rdi 

  call strlen 
  mov rdx,rax 
  pop rsi 
  mov rdi,1 
  mov rax,1 
  syscall

  ret

strcmp:

  push rbp 
  mov rbp,rsp 

  push rdi 
  push rsi 

.L01:

  mov al,byte [rdi]
  mov dl, byte [rsi]
  cmp al,dl 
  jne .L03
  cmp al,0 
  je .L02 
  inc rdi 
  inc rsi  
  jmp .L01 

.L02:

  mov eax,1  ; 1 true 
  jmp .L04

.L03:
 
  xor eax,eax ; 0 false 

.L04:

  pop rsi 
  pop rdi 

  leave
  ret 
