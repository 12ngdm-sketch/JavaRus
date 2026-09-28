#!/usr/bin/env python3
# pyromide_interface.py — проверка графики

import sys
import os

def main():
    print("=== Pyromide Интерфейс: проверка графики ===")
    
    if len(sys.argv) < 2:
        print("Ошибка: не указано имя проекта")
        return
    
    name = sys.argv[1]
    base = "/sdcard/проект javarus"
    java_file = f"{base}/temp/{name}.java"
    
    if not os.path.exists(java_file):
        print(f"Ошибка: файл {java_file} не найден")
        return
    
    # Простая проверка: ищем слова, связанные с графикой
    with open(java_file, "r", encoding="utf-8") as f:
        content = f.read()
    
    graphic_keywords = ["draw", "paint", "canvas", "sprite", "image", "frame", "render"]
    has_graphic = any(word in content.lower() for word in graphic_keywords)
    
    if has_graphic:
        print("Графика в порядке. Отправляю в соединение...")
        flag_file = f"{base}/temp/{name}.graphic_ok"
        with open(flag_file, "w") as f:
            f.write("ok")
        print(f"Флаг создан: {flag_file}")
    else:
        print("ВЫ НЕ ПРАВИЛЬНО НАПИСАЛИ КОД")
        print("ПЕРЕПИШИТЕ КОД И ПОПРОБУЙТЕ ЕЩЁ РАЗ")

if __name__ == "__main__":
    main()