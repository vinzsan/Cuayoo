%include "include/standard.inc"
%include "include/mutex.inc"

; struct ChunkList 
CHUNK_LIST_SIZE_offset           equ 0  ; u64 -> 8
CHUNK_LIST_NEXT_CHUNK_offset     equ 12  ; non stack grows up u64 
CHUNK_LIST_FLAGS_offset          equ 16 ; u32 
CHUNK_LIST_FLAGS_VERIFIED_offset equ 20 ; u32 
CHUNK_LIST_ALIGMENT              equ 32 ; benerr  

PROT_READ                        equ 0x01 
PROT_WRITE                       equ 0x02 

SYS_mmap                         equ 9
SYS_munmap                       equ 11 
SYS_mprotect                     equ 10 

MAP_PRIVATE                      equ 0x02 
MAP_ANONYMOUS                    equ 0x22

ARENA_INIT_SIZE                  equ (1024 * 8)

struc CHUNK_CONTEXT 
  .resq size_chunk_list 1 
  .resq next_chunk_list 1 
  .resd chunk_status    1 
  .resd chunk_number    1 
endstruc 

struc ARENA_CONTEXT
  .resq size_arena_list 1
  .resq offset_arena    1 
  .resq next_arena_list 1
  .resd arena_status    1
  .resd arena_number    1

  .resq head_chunk_offset 1
  .resq tail_chunk_offset 1
endstruc

section .rodata
  ERR_L1 db "arena_drop_chunk(): error failed to find head offset",0x0A,0 
  ERR_L2 db "arena_drop_chunk(): error failed to reserve chunk size",0x0A,0 

section .data 
  arena_mutex_guard_lock dd 0

section .text 
  global init_arena 
  global allocate
  global destroy

init_arena:

  ; params 
  ; (void) non params 

  push rbp 
  mov rbp,rsp 
  
  xor rdi,rdi 
  mov rsi,ARENA_INIT_SIZE + ARENA_CONTEXT_size 
  mov rdx,PROT_READ | PROT_WRITE 
  mov r10,MAP_PRIVATE | MAP_ANONYMOUS
  mov r8,-1 
  xor r9,r9 
  mov rax,SYS_mmap
  syscall 

  cmp rax,-1 
  je .MAP_ERR_INIT 

  xor rdx,rdx 

  mov qword [rax + ARENA_CONTEXT.size_arena_list],ARENA_INIT_SIZE
  mov qword [rax + ARENA_CONTEXT.next_arena_list],rdx 

  mov qword [rax + ARENA_CONTEXT.arena_status],ARENA_USED 
  mov qword [rax + ARENA_CONTEXT.arena_number],ARENA_NUM 

  mov qword [rax + ARENA_CONTEXT.head_chunk_offset],ARENA_CONTEXT_size 
  ;; jika 0 akan overlaps dengan metadata arena
  mov qword [rax + ARENA_CONTEXT.tail_chunk_offset],rdx 

  leave 
  ret 

.MAP_ERR_INIT:

  ud2 

;; 

arena_drop_chunk:

  push rbp 
  mov rbp,rsp 

  ;; take metadata 
  ;; params rdi,rsi(struct ARENA_CONTEXT *,size_t size)
  push rbx 

  test rdi,rdi 
  jz .ERR_ARENA_INVALID

  and rsi,-16 

  cmp rsi,-1 
  je .ERR_SIZE_OUT_BOUND

  ; mov rax,[rdi + ARENA_CONTEXT.head_chunk_offset]
  ; test rax,rax 
  ; jz .ERR_ARENA_INVALID ;; chunk invalid 

  mov rax,[rdi + ARENA_CONTEXT.head_chunk_offset]
  test rax,rax 
  jnz .SHRINK_BLOCK_ARENA

  lea rdi,[rel ERR_L1]
  call print 

  ud2 

.SHRINK_BLOCK_ARENA:

  mov rax,[rdi + ARENA_CONTEXT.offset_arena]
  add rax,rsi 

  mov rdx,[rdi + ARENA_CONTEXT.size_arena_list]
  add rdx,ARENA_CONTEXT_size 

  cmp rax,rdx 
  jl .L01 

  lea rdi,[rel ERR_L3]
  call print 

  xor rax,rax 

.L01:

  mov rbx,[rdi + ARENA_CONTEXT.offset_arena]
  lea rax,[rdi + rbx]

  add rbx,rsi 
  add qword [rdi + ARENA_CONTEXT.offset_arena],rbx 

  pop rbx 
  leave 
  ret 

.ERR_ARENA_INVALID:

  pop rbx 
  ud2 

.ERR_SIZE_OUT_BOUND:

  pop rbx 

  lea rdi,[rel ERR_L2]
  call print 

  ud2 
  

arena_src_chunk_free:

  push rbp 
  mov rbp,rsp 
  push rbx 
  ;; params rdi(struct ARENA_CONTEXT *)
  ;;        rsi(size_t chunk_requested_size)

  xor rax,rax ;; clean rax for return 

  test rdi,rdi ;; arena not found 
  jz .ERR_ARENA_INVALID ;; trap 

  cmp rdi,0 ;; if size > MAX_64
  jnbe .SRC_CHUNK_FREE

.ERR_ARENA_INVALID:

  pop rbx ;; return rax NULL(INVALID) trap 

  leave
  ud2 

.SRC_CHUNK_FREE:

  mov rbx,[rdi + ARENA_CONTEXT.head_chunk_offset]

  test rbx,rbx 
  jz .ERR_ARENA_INVALID ;; head not found trap 

  cmp dword [rbx + ARENA_CONTEXT.]

  leave 
  ret 
