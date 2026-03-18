%include "include/standard.inc"
%include "include/memory.inc"
%include "include/mutex.inc"

; struct ChunkList 
CHUNK_LIST_SIZE_offset           equ 0  ; u64 -> 8
CHUNK_LIST_NEXT_CHUNK_offset     equ 12  ; non stack grows up u64 
CHUNK_LIST_FLAGS_offset          equ 16 ; u32 
CHUNK_LIST_FLAGS_VERIFIED_offset equ 20 ; u32 
CHUNK_LIST_ALIGMENT              equ 32 ; benerr  

;bener kayaknya OCD juga wkwk

section .data 
  arena_list_head dq 0 
  arena_list_tail dq 0 

  chunk_list_head dq 0
  chunk_list_tail dq 0 

section .text 
  global init_arena 
  global allocate
  global destroy

init_arena:

  ; params 
  ; (void) non params 
