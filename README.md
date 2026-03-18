## C700RT06-BL

Custom allocator dengan `brk()` dan guard `futex()`
<br>

**Kenapa pakai `brk()` bukan `mmap()`?**
- Mencoba memahami kegunaan DSA
- Memahami arsitektur **lawas**
- Suka aja make `brk()` tapi mmap juga
- **Memahami multithread**

### Tabel

| Fitur | Desc | Digunakan untuk |
|---------|-------------|-------------|
| **`alloc`** | Mengalokasikan memory via brk | reserve memory heap |
| **`mutex`** | Mengunci state / resource | menghindari race |
| **`free`** | Menandai block | Digunakan untuk flags reuse block |

> **Note**: Masih pemula njir kalo ada issue yawda si, [ide saya](https://medium.com/@sgn00/high-performance-memory-management-arena-allocators-c685c81ee338) silahkan jika ada **saran** atau **tambahan**
