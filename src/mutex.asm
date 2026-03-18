%include "include/standard.inc"

MUTEX_WAITERS      equ 2
MUTEX_LOCK         equ 1
MUTEX_UNLOCK       equ 0 

FUTEX_WAIT equ 0 
FUTEX_WAKE equ 1 

SYS_futex equ 202 

section .text 
  global mutex_lock 
  global mutex_unlock 

mutex_lock:

  ; atomic 
  ; rdi mutex_t *

.ITER:

  mov eax,MUTEX_UNLOCK ;  expected int 
  mov ecx,MUTEX_LOCK
  lock cmpxchg dword [rdi],ecx 
  je .UNLOCK 

.WAITERS:

  mov eax,MUTEX_UNLOCK
  mov ecx,MUTEX_LOCK
  lock cmpxchg dword [rdi],ecx 
  je .UNLOCK ; unlock via waiters 

  mov eax,MUTEX_UNLOCK
  je .LOCK_TWICE 

  push rdi ; store rdi ptr (mutex* ptr)

  mov rax,SYS_futex
  mov rsi,FUTEX_WAIT 
  mov rdx,MUTEX_WAITERS 
  xor r10,r10 
  xor r8,r8
  xor r9,r9
  syscall 

  pop rdi ; restore rdi ptr 

.LOCK_TWICE:

  mov eax,MUTEX_UNLOCK
  mov ecx,MUTEX_LOCK
  lock cmpxchg [rdi],ecx 
  jne .WAITERS

.UNLOCK:

  ret 

mutex_unlock:

  ; rdi (mutex_t *)
  mov eax,MUTEX_LOCK 
  lock xadd dword [rdi],eax 
  
  mov eax,-1 
  lock xadd dword [rdi],eax 

  cmp eax,MUTEX_LOCK ; 1 no waiters (2)
  je .NO_WAITERS 

  mov dword [rdi],MUTEX_UNLOCK

  mov rsi,FUTEX_WAKE
  mov rdx,1 ; 1 thread wake 
  xor r10,r10 
  xor r8,r8 
  xor r9,r9 
  mov rax,SYS_futex 
  syscall

.NO_WAITERS:

  ret 
