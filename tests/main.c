#include <stdio.h>
#include <stdlib.h>

extern void *alloc(size_t n);
extern void free(void *ptr);

int main(){
  void *addr = alloc(1024);
  free(addr);
  void *readdr = alloc(32);
  return 0;
}
