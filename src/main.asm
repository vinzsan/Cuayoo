%include "include/standard.inc"
%include "include/memory.inc"
%include "include/mutex.inc"

struc VECTOR_CONTEXT 
  .data_ptr resq 1 
  .capacity resq 1
  .size     resq 1
endstruc

section .rodata
  L1 db "Test",0x0A,0 

section .text 
  global _start

init_vector:

  push rbp 
  mov rbp,rsp 

  push rbx 
  mov rbx,rdi 

  mov qword [rbx + VECTOR_CONTEXT.capacity],8
  mov qword [rbx + VECTOR_CONTEXT.size],0 

  mov rdi,16
  call alloc 

  mov qword [rbx + VECTOR_CONTEXT.data_ptr],rax 
  pop rbx 

  leave 
  ret 

;;

vector_push:

  push rbp 
  mov rbp,rsp 
  push rbx

  push rsi ;; backup data 
  mov rbx,rdi 

  mov rax,[rdi + VECTOR_CONTEXT.size]
  cmp rax,[rdi + VECTOR_CONTEXT.capacity]
  jnz .DONE

.NEW_MEMBER:

  push r12 

  mov rax,[rbx + VECTOR_CONTEXT.capacity]
  mov rcx,2  
  mul rcx 

  push rax ;; new size backup 

  mov rcx,8
  mul rcx 

  mov rdi,rax 
  call alloc 

  mov r12,rax 

  mov rdx,[rbx + VECTOR_CONTEXT.data_ptr]
  push rdx ;; ptr backup 

  xor rcx,rcx 

.FOR:

  cmp rcx,[rbx + VECTOR_CONTEXT.size]
  jge .BREAK

  mov rax,qword [rdx + rcx * 8]
  mov qword [r12 + rcx * 8],rax

  inc rcx 
  jmp .FOR 

.BREAK:

  pop rdi 
  call free 

  mov qword [rbx + VECTOR_CONTEXT.data_ptr],r12 
  pop rax 
  mov qword [rbx + VECTOR_CONTEXT.capacity],rax 

  pop r12 
  
.DONE:

  pop rsi 

  mov qword [rbx + VECTOR_CONTEXT.data_ptr],rsi 
  inc qword [rbx + VECTOR_CONTEXT.size]

  pop rbx 

  leave 
  ret 

_start:

  and rsp,-16 
  xor rbp,rbp 

  push rbp 
  mov rbp,rsp 
  sub rsp,64 

  push rbx 
  xor rdx,rdx 
  mov rdx,10

.iter:

  cmp rdx,0 
  je .done 

  push rdx  
  mov rdi,1024
  call alloc 

  mov rbx,rax 
 
  mov rdi,rbx 
  xor al,al
  mov rcx,1024
  cld 
  rep stosb
  pop rdx 

  mov rdi,rbx 
  call free

  dec rdx 
  jmp .iter 

.done:

  pop rbx 
  leave 
  
  mov rax,60
  xor rdi,rdi 
  syscall
