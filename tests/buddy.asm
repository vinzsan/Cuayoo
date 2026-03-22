struc METADATA
  .head_break: resq 1
  .tail_break: resq 1
endstruc
;; nggak ada masih template kayaknya 
;; kalo udah ada initnya kayaknya ada sendiri 

section .rodata
  L1 db "Coppy to buffer Test",0x0A,0 

section .text 
  global _start

_start:

  and rsp,-16 
  xor rbp,rbp 
  push rbp 
  mov rbp,rsp 


  mov rax,12 
  xor rdi,rdi ; init break pertama jadi brk(NULL)
  syscall 

  push rbx 
  mov rbx,rax 

  lea rdi,[rbx + 1024]
  mov rax,12 
  syscall 

  mov qword [rbx + METADATA.head_break],rbx 
  mov qword [rbx + METADATA.tail_break],rax 

  lea rsi,[rel L1]
  lea rdi,[rbx + METADATA.head_break]
  mov rcx,32 
  rep movsb 

  mov rax,1 
  mov rdi,1 
  lea rsi,[rbx + METADATA.head_break]
  mov rdx,32
  syscall

  leave 
  
  mov rax,60
  xor rdi,rdi 
  syscall 
