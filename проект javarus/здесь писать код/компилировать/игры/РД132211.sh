#!/bin/bash
echo "=== Сборка РД132211 ==="
cd "/sdcard/проект javarus/компилятор"
./Termux_compile.sh РД132211
./Jvdroid_osnova РД132211
./pyromide_interface РД132211
./connection РД132211
./AndroidSDK_build РД132211
echo "=== Готово! ==="
