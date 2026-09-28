#!/bin/bash
# Termux_compile.sh — перевод JavaRus → Java
# Использование: ./Termux_compile.sh <имя_проекта>

NAME=$1

if [ -z "$NAME" ]; then
    echo "Ошибка: не указано имя проекта"
    echo "Использование: ./Termux_compile.sh <имя_проекта>"
    exit 1
fi

BASE="/sdcard/проект javarus"
JRUS_FILE="$BASE/здесь писать код/игры/$NAME/$NAME.jrus"
OUTPUT_DIR="$BASE/temp"                    # <-- ИЗМЕНЕНО: temp в корне
OUTPUT_FILE="$OUTPUT_DIR/$NAME.java"

echo "=== Termux Compile: $NAME ==="
echo "Читаю: $JRUS_FILE"

# Создаём папку temp, если нет
mkdir -p "$OUTPUT_DIR"

# Проверяем, есть ли файл
if [ ! -f "$JRUS_FILE" ]; then
    echo "Ошибка: файл $JRUS_FILE не найден"
    exit 1
fi

# Простой перевод JavaRus → Java
echo "public class $NAME {" > "$OUTPUT_FILE"
echo "    public static void main(String[] args) {" >> "$OUTPUT_FILE"

while IFS= read -r line; do
    [[ -z "$line" || "$line" == //* ]] && continue
    
    if [[ "$line" == вывести* ]]; then
        TEXT=$(echo "$line" | sed 's/вывести(//;s/);//')
        echo "        System.out.println($TEXT);" >> "$OUTPUT_FILE"
    else
        echo "        // $line" >> "$OUTPUT_FILE"
    fi
done < "$JRUS_FILE"

echo "    }" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Готово: $OUTPUT_FILE"
echo "=== Termux Compile завершён ==="

exit 0