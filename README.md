# CRC32反查 
反查某平台弹幕发送者，使用WebAssembly

## 编译
```batch
clang -flto -O3 -nostdlib -fno-builtin -ffreestanding -mexec-model=reactor --target=wasm32 -Wl,--strip-all -Wl,--no-entry -Wl,--allow-undefined -Wl,--compress-relocations -Wl,--export-dynamic -o dec-crc32-cracker.wasm dec-crc32-cracker.c

zig build-exe -O ReleaseSmall -target wasm32-freestanding dec-crc32-cracker.zig -flto -fno-builtin -fno-entry --export=init --export=getIndexes --export=crc32_dec --export=checkIndex --export=findIndex

zig build-exe main.zig
```

## 鸣谢
文章：<https://moepus.oicp.net/2016/11/27/crccrack/> 作者：MoePus  
<https://github.com/ProgramRipper/crc32Cracker>  
<https://github.com/esterTion/BiliBili_crc2mid>  