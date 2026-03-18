section .rodata
  L1 db "float: ",0 

section .text 
  global _start

_itoa:

  push rbp 
  mov rbp,rsp 

  ; rdi buffer 
  ; rsi number 
  push rbx 
  push r12 

  mov rbx,rdi 
  mov r12,rsi 

  mov byte [rbx],0 
  mov byte [rbx + 1],0x0A

  test r12,r12 
  jnz .iter 

  mov rax,1 
  leave 
  ret 

.iter: 

  leave 
  ret 

_start:

  and rsp,-16 
  xor rbp,rbp 

  mov rdi,128
  call alloc 

  mov dword [rax + 4],0x41280000 
  mov dword [rax + 8],0x41280000

  movss xmm0,[rax + 4]
  movss xmm1,[rax + 8]
  addss xmm0,xmm1 

  mov dword [rax + 16],0x42c80000 
  mulss xmm0,[rax + 16]
  cvtss2si r12,xmm0 

  push rax 

  mov rdi,r12 
  lea rsi,[rax + 32]
  call itoa64

  lea rdi,[rel L1]
  call print 

  pop rax 
  push rax 

  add byte [rax + 32],0
  lea rdi,[rax + 32]
  call print

  pop rdi 
  call free 

  mov rdi,16 
  call alloc 

  mov r12,rax 

  mov qword [r12],3
  mov qword [r12 + 8],0 

  push rbx 
  mov ebx,10 

for:

  test ebx,ebx 
  jz .done

  mov rax,230 
  xor rdi,rdi 
  xor rsi,rsi 
  lea rdx,[r12]
  xor r10,r10 
  syscall 
  
  mov rdi,1024 * 1024 * 10
  movzx rbx,ebx 
  imul rdi,rbx
  call alloc

  dec ebx 
  jmp for 

.done:

  pop rbx 

  mov rax,60
  xor rdi,rdi 
  syscall

%include "include/standard.inc"
%include "include/memory.inc"
  
