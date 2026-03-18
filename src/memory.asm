stack_max_chunk_align     equ 4 
stack_offset_verificate   equ 3 
stack_offset_flags_chunk  equ 2 
stack_offset_next_chunk   equ 1 
stack_offset_size_chunk   equ 0
; offset stack minus
OFFSET_CHUNK_SIZE         equ 0 
OFFSET_CHUNK_NEXT_CHUNK   equ 8 
OFFSET_CHUNK_VERIF        equ 16 
OFFSET_CHUNK_FLAGS        equ 20 
OFFSET_CHUNK_TOTAL        equ 32 

VERIFICATE_BLOCK          equ 0xCCCCCC00

FLAGS_CHUNK_FREE          equ 1
FLAGS_CHUNK_USED          equ 0

EXPAND_ERR_VALUE          equ -1 

SYS_munmap                equ 11
SYS_mprotect              equ 10
SYS_brk                   equ 12
SYS_mmap                  equ 9

PROT_NONE                 equ 0
PROT_READ                 equ 1 
PROT_WRITE                equ 2 
PROT_EXEC                 equ 4 

MAP_PRIVATE               equ 0x02 
MAP_ANONYMOUS             equ 0x22

struc ARENA_METADATA 
    .size_arena:  resq 1
    .next_arena:  resq 1 
    .flags_arena: resq 1 
    .hash_arena:  resq 1
endstruc 

struc CHUNK_METADATA
    .size_chunk:  resq 1 
    .flags_chunk: resd 1 
    .next_chunk:  resq 1
endstruc

%include "include/standard.inc"
%include "include/mutex.inc"

section .rodata
  error_allocated   db "ERROR: failed allocate memory",0x0A,0 
  error_double_free db "abort(): double free detected",0x0A,0 
  corrupt_block     db "abort(): missing metadata",0x0A,0 

section .data 
  static_head_break_offset dq 0 
  static_tail_break_offset dq 0 

  static_head_chunk        dq 0  
  static_tail_chunk        dq 0 

  static_mutex_guard       dd 0 

  static_arena_head_list   dq 0 
  static_arena_tail_list   dq 0 

  static_chunk_head_list   dq 0 
  static_chunk_tail_list   dq 0 

section .bss 

  ; size = r/m64,flags = r/m32,verificate = r/m32,next data = r/m64 ,alignment = 8 byte 

section .text 
  global _sbrk
  global alloc 
  global free 

_sbrk:

  ; rdi (intptr_t n)
  push rbx 
  push rdi 

  mov rax,SYS_brk
  xor rdi,rdi 
  syscall 

  mov rbx,rax 

  pop rdi 
  lea rsi,[rbx + rdi]

  mov rdi,rsi 
  mov rax,SYS_brk
  syscall

  mov rsi,rax

  cmp rax,EXPAND_ERR_VALUE
  jle .ERR_EXPAND

  mov qword [rel static_tail_break_offset],rsi 

  mov rax, qword [rel static_head_break_offset]
  cmp rax,0 
  je .STATIC_HEAD_EMTPY 
  jmp .END 

.STATIC_HEAD_EMTPY:

  mov qword [rel static_head_break_offset],rbx 

  mov rax,rbx 
  jmp .END 

.ERR_EXPAND:

  lea rdi,[rel error_allocated]
  call print 

  xor rax,rax 

.END:

  mov rax,rbx 

  pop rbx 
  ret 

  ; end _sbrk 

src_free_chunk:

  ;rdi (size_t size)

  push rbp 
  mov rbp,rsp 

  mov rax,[rel static_head_chunk]
  test rax,rax
  jz .OVERFLOW_SIZE_T_N_NOCHUNK

.ITER_SRC:

  cmp dword [rax + OFFSET_CHUNK_FLAGS],FLAGS_CHUNK_FREE
  jne .NEXT_CHUNK 

  mov rdx,qword [rax + OFFSET_CHUNK_SIZE]
  cmp rdx,rdi 
  jc .NEXT_CHUNK

  jmp .END_SRC_CHUNK

.NEXT_CHUNK:

  mov rax,qword [rax + OFFSET_CHUNK_NEXT_CHUNK]
  test rax,rax 
  jz .OVERFLOW_SIZE_T_N_NOCHUNK
  
  jmp .ITER_SRC

.OVERFLOW_SIZE_T_N_NOCHUNK:

  xor rax,rax
  
.END_SRC_CHUNK:

  leave 
  ret 


alloc:

  ; rdi(size_t n) allocated  N bytes of memory 

  push rbp 
  mov rbp,rsp 
  push rbx 

  and rdi,-16 ; alignment (rdi size)
  mov rbx,rdi 

  lea rdi,[rel static_mutex_guard]
  call mutex_lock 

  mov rdi,rbx 
  call src_free_chunk

  test rax,rax 
  jz .CREATE_NEW_CHUNK 

  ; PTR arith 
  push rax 
  lea rdi,[rel static_mutex_guard]
  call mutex_unlock 
  pop rax 

  mov dword [rax + OFFSET_CHUNK_FLAGS],FLAGS_CHUNK_USED
  lea rax,[rax + OFFSET_CHUNK_TOTAL]

  pop rbx 
  
  leave
  ret ; return if block available 

.CREATE_NEW_CHUNK:

  add rdi,OFFSET_CHUNK_TOTAL
  call _sbrk 

  ; rax (void *) from ptr 
  test rax,rax 
  jz .ERR_NULL

  mov qword [rax + OFFSET_CHUNK_SIZE],rbx

  xor rdx,rdx 
  mov qword [rax + OFFSET_CHUNK_NEXT_CHUNK],rdx 

  mov dword [rax + OFFSET_CHUNK_FLAGS],FLAGS_CHUNK_USED 

  mov dword [rax + OFFSET_CHUNK_VERIF],VERIFICATE_BLOCK

  cmp qword [rel static_head_chunk],rdx 
  jne .UPDATE_TAIL

  mov qword [rel static_head_chunk],rax 
  mov qword [rel static_tail_chunk],rax 

  jmp .DONE_TAIL

.UPDATE_TAIL:

  mov rcx,qword [rel static_tail_chunk]
  mov qword [rcx + OFFSET_CHUNK_NEXT_CHUNK],rax 
  mov qword [rel static_tail_chunk],rax 

.DONE_TAIL:
  lea rax,[rax + OFFSET_CHUNK_TOTAL]
  push rax 

  lea rdi,[rel static_mutex_guard]
  call mutex_unlock 

  pop rax 
  pop rbx 
  leave
  ret 

  align 16,db 0x90 

.ERR_NULL:

  xor rax,rax 

  lea rdi,[rel static_mutex_guard]
  call mutex_unlock

  pop rbx
  leave
  ret 

free:

  ; rdi(void *ptr)

  push rbp
  mov rbp,rsp 

  lea rax,[rdi - OFFSET_CHUNK_TOTAL]
  test rax,rax 
  jz .DONE_FREE

  cmp dword [rax + OFFSET_CHUNK_FLAGS],FLAGS_CHUNK_FREE
  je .ERR_DOUBFREE 

  cmp dword [rax + OFFSET_CHUNK_VERIF],VERIFICATE_BLOCK
  jne .CORRUPT_BLOCK

  mov dword [rax + OFFSET_CHUNK_FLAGS],FLAGS_CHUNK_FREE

.DONE_FREE:

  leave 
  ret 

  align 16,db 0x90

.ERR_DOUBFREE:

  lea rdi,[rel error_double_free]
  call print 

  ud2 

.CORRUPT_BLOCK:

  lea rdi,[rel corrupt_block]
  call print 

  ud2 

; end brk 

init_page:

  push rbp 
  mov rbp,rsp 

  lea rax,[rel static_head_break_offset]
  mov rax,ARENA_METADATA

  leave 
  ret 

page_alloc:

  push rbp 
  mov rbp,rsp 


page_free:

  mov rax,SYS_munmap 
  syscall 
