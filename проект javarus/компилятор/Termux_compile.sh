#!/bin/bash
# Termux_compile.sh — перевод JavaRus → Java (v0.1)
# Использование: ./Termux_compile.sh <имя_проекта>

NAME=$1

if [ -z "$NAME" ]; then
    echo "Ошибка: не указано имя проекта"
    echo "Использование: ./Termux_compile.sh <имя_проекта>"
    exit 1
fi

BASE="/sdcard/проект javarus"
JRUS_FILE="$BASE/здесь писать код/игры/$NAME/$NAME.jrus"
OUTPUT_DIR="$BASE/temp"
OUTPUT_FILE="$OUTPUT_DIR/$NAME.java"

echo "=== Termux Compile: $NAME ==="
echo "Читаю: $JRUS_FILE"

mkdir -p "$OUTPUT_DIR"

if [ ! -f "$JRUS_FILE" ]; then
    echo "Ошибка: файл $JRUS_FILE не найден"
    exit 1
fi

# ====== ЗАГОЛОВОК JAVA-ФАЙЛА ======
cat > "$OUTPUT_FILE" << 'EOF'
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.ArrayList;

public class GAME_NAME extends JPanel {
    static JFrame frame;
    static GAME_NAME panel;

    // Игрок
    static int playerX = 100, playerY = 100;
    static int playerHP = 10, playerAmmo = 5;

    // Камера
    static int cameraX = 0, cameraY = 0;

    // Объекты
    static ArrayList<int[]> walls = new ArrayList<>();
    static ArrayList<int[]> enemies = new ArrayList<>();
    static ArrayList<JButton> buttons = new ArrayList<>();
    static ArrayList<String> texts = new ArrayList<>();
    static ArrayList<int[]> textPos = new ArrayList<>();

    public GAME_NAME() {
        setLayout(null);
        setBackground(Color.BLACK);
    }

    public void paintComponent(Graphics g) {
        super.paintComponent(g);
        g.setColor(Color.BLACK);
        g.fillRect(0, 0, getWidth(), getHeight());

        // Стены
        g.setColor(Color.GRAY);
        for (int[] w : walls) {
            g.fillRect(w[0] - cameraX, w[1] - cameraY, w[2], w[3]);
        }

        // Игрок
        g.setColor(Color.BLUE);
        g.fillRect(playerX - cameraX, playerY - cameraY, 40, 60);

        // Враги
        g.setColor(Color.ORANGE);
        for (int[] e : enemies) {
            g.fillRect(e[0] - cameraX, e[1] - cameraY, 40, 60);
        }

        // Тексты
        g.setColor(Color.WHITE);
        g.setFont(new Font("Arial", Font.BOLD, 16));
        for (int i = 0; i < texts.size(); i++) {
            g.drawString(texts.get(i), textPos.get(i)[0], textPos.get(i)[1]);
        }

        // HUD
        g.setColor(Color.WHITE);
        g.drawString("HP: " + playerHP, 20, 20);
        g.drawString("Ammo: " + playerAmmo, 20, 40);
    }

    public static void main(String[] args) {
        frame = new JFrame("GAME_NAME");
        frame.setSize(800, 600);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        panel = new GAME_NAME();
        frame.add(panel);
        frame.setVisible(true);

        // Игровой цикл (перерисовка)
        new Timer(16, e -> panel.repaint()).start();
    }
}
EOF

# Заменяем GAME_NAME на имя проекта
sed -i "s/GAME_NAME/$NAME/g" "$OUTPUT_FILE"

# ====== ЧТЕНИЕ КОДА JAVARUS ======
while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$line" ]] && continue

    # === ВЫВОД ===
    if [[ "$line" == вывести* ]]; then
        TEXT=$(echo "$line" | sed 's/вывести(//;s/);//')
        echo "        System.out.println($TEXT);" >> "$OUTPUT_FILE"
        continue
    fi

    # === ПЕРЕМЕННЫЕ ===
    if [[ "$line" == целое* ]]; then
        VAR=$(echo "$line" | sed 's/целое //;s/;//')
        echo "        int $VAR;" >> "$OUTPUT_FILE"
        continue
    fi
    if [[ "$line" == строка* ]]; then
        VAR=$(echo "$line" | sed 's/строка //;s/;//')
        echo "        String $VAR;" >> "$OUTPUT_FILE"
        continue
    fi

    # === СОЗДАТЬ КНОПКУ ===
    if [[ "$line" == создать\ кнопку* ]]; then
        # Извлекаем данные: надпись, координаты, размер, действие
        LABEL=$(echo "$line" | grep -oP 'надпись на кнопке "\K[^"]+')
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        ACTION=$(echo "$line" | grep -oP 'что делает кнопка \K.+')

        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')
        W=$(echo $POS | awk '{print $3}')
        H=$(echo $POS | awk '{print $4}')

        # Генерируем Java-код для кнопки
        cat >> "$OUTPUT_FILE" << BUTTON_EOF

        {
            JButton btn = new JButton("$LABEL");
            btn.setBounds($X, $Y, $W, $H);
            btn.addActionListener(e -> {
                System.out.println("Кнопка $LABEL нажата");
            });
            panel.add(btn);
            panel.revalidate();
        }
BUTTON_EOF
        continue
    fi

    # === СОЗДАТЬ ТЕКСТ ===
    if [[ "$line" == создать\ текст* ]]; then
        TEXT=$(echo "$line" | grep -oP 'текст "\K[^"]+')
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')

        cat >> "$OUTPUT_FILE" << TEXT_EOF

        {
            texts.add("$TEXT");
            textPos.add(new int[]{$X, $Y});
        }
TEXT_EOF
        continue
    fi

    # === СОЗДАТЬ ИГРОК ===
    if [[ "$line" == создать\ игрок* ]]; then
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')
        echo "        playerX = $X; playerY = $Y;" >> "$OUTPUT_FILE"
        continue
    fi

    # === СОЗДАТЬ КАМЕРУ ===
    if [[ "$line" == создать\ камеру* ]]; then
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')
        echo "        cameraX = $X; cameraY = $Y;" >> "$OUTPUT_FILE"
        continue
    fi

    # === СОЗДАТЬ СТЕНУ ===
    if [[ "$line" == создать\ стену* ]]; then
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        W=$(echo "$line" | grep -oP 'размер \K[\d ]+')
        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')
        SW=$(echo $W | awk '{print $1}')
        SH=$(echo $W | awk '{print $2}')
        echo "        walls.add(new int[]{$X, $Y, $SW, $SH});" >> "$OUTPUT_FILE"
        continue
    fi

    # === ЕСЛИ ===
    if [[ "$line" == если* ]]; then
        COND=$(echo "$line" | sed 's/если\s*(\s*//;s/\s*)\s*{.*//')
        BODY=$(echo "$line" | sed 's/.*{\s*//;s/\s*}.*//')
        COND=$(echo "$COND" | sed 's/больше/>/;s/меньше/</;s/равно/==/;s/не равно/!=/')
        echo "        if ($COND) { $BODY }" >> "$OUTPUT_FILE"
        continue
    fi

    # === ПОКА ===
    if [[ "$line" == пока* ]]; then
        COND=$(echo "$line" | sed 's/пока\s*(\s*//;s/\s*)\s*{.*//')
        BODY=$(echo "$line" | sed 's/.*{\s*//;s/\s*}.*//')
        COND=$(echo "$COND" | sed 's/больше/>/;s/меньше/</;s/равно/==/;s/не равно/!=/')
        echo "        while ($COND) { $BODY }" >> "$OUTPUT_FILE"
        continue
    fi

done < "$JRUS_FILE"

# === СОЗДАТЬ ВРАГА ===
if [[ "$line" == создать\ врага* ]]; then
    POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
    HP=$(echo "$line" | grep -oP 'здоровье \K\d+')
    X=$(echo $POS | awk '{print $1}')
    Y=$(echo $POS | awk '{print $2}')
    [ -z "$HP" ] && HP=10
    echo "        enemies.add(new int[]{$X, $Y, $HP});" >> "$OUTPUT_FILE"
    continue
fi

# === СОЗДАТЬ ДВЕРЬ ===
if [[ "$line" == создать\ дверь* ]]; then
    POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
    X=$(echo $POS | awk '{print $1}')
    Y=$(echo $POS | awk '{print $2}')
    echo "        // Дверь на координатах ($X, $Y)" >> "$OUTPUT_FILE"
    echo "        walls.add(new int[]{$X, $Y, 40, 80});" >> "$OUTPUT_FILE"
    continue
fi

# === СОЗДАТЬ ПРЕДМЕТ ===
if [[ "$line" == создать\ предмет* ]]; then
    TYPE=$(echo "$line" | grep -oP 'тип "\K[^"]+')
    POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
    X=$(echo $POS | awk '{print $1}')
    Y=$(echo $POS | awk '{print $2}')
    echo "        // Предмет $TYPE на координатах ($X, $Y)" >> "$OUTPUT_FILE"
    continue
fi

# === СОЗДАТЬ СВЕТ ===
if [[ "$line" == создать\ свет* ]]; then
    POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
    X=$(echo $POS | awk '{print $1}')
    Y=$(echo $POS | awk '{print $2}')
    echo "        // Свет на координатах ($X, $Y)" >> "$OUTPUT_FILE"
    continue
fi

# === СОЗДАТЬ ЗВУК ===
if [[ "$line" == создать\ звук* ]]; then
    FILE=$(echo "$line" | grep -oP 'файл "\K[^"]+')
    echo "        // Звук: $FILE" >> "$OUTPUT_FILE"
    continue
fi

# === ДВИГАТЬ ===
if [[ "$line" == двигать* ]]; then
    ARGS=$(echo "$line" | sed 's/двигать(//;s/);//')
    echo "        // двигать($ARGS)" >> "$OUTPUT_FILE"
    continue
fi

# === ЖДАТЬ ===
if [[ "$line" == ждать* ]]; then
    MS=$(echo "$line" | sed 's/ждать(//;s/);//')
    echo "        // ждать($MS мс)" >> "$OUTPUT_FILE"
    continue
fi

# === ВЫСТРЕЛИТЬ ===
if [[ "$line" == выстрелить* ]]; then
    echo "        if (playerAmmo > 0) { playerAmmo--; }" >> "$OUTPUT_FILE"
    continue
fi

# === ЕСЛИ_УМЕР ===
if [[ "$line" == если_умер* ]]; then
    echo "        // если_умер" >> "$OUTPUT_FILE"
    continue
fi

# === ЕСЛИ_СТОЛКНУЛСЯ ===
if [[ "$line" == если_столкнулся* ]]; then
    echo "        // если_столкнулся" >> "$OUTPUT_FILE"
    continue
fi

    # === СОЗДАТЬ КОМНАТУ ===
    if [[ "$line" == создать\ комнату* ]]; then
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        SIZE=$(echo "$line" | grep -oP 'размер \K[\d ]+')
        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')
        W=$(echo $SIZE | awk '{print $1}')
        H=$(echo $SIZE | awk '{print $2}')
        cat >> "$OUTPUT_FILE" << ROOM_EOF
        // Комната ($X, $Y) размером ($W x $H)
        walls.add(new int[]{$X, $Y, $W, 20});
        walls.add(new int[]{$X, $Y + $H - 20, $W, 20});
        walls.add(new int[]{$X, $Y, 20, $H});
        walls.add(new int[]{$X + $W - 20, $Y, 20, $H});
ROOM_EOF
        continue
    fi

    # === СОЗДАТЬ ПОЛ ===
    if [[ "$line" == создать\ пол* ]]; then
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        SIZE=$(echo "$line" | grep -oP 'размер \K[\d ]+')
        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')
        W=$(echo $SIZE | awk '{print $1}')
        H=$(echo $SIZE | awk '{print $2}')
        echo "        // Пол ($X, $Y) размером ($W x $H)" >> "$OUTPUT_FILE"
        continue
    fi

    # === СОЗДАТЬ ПОТОЛОК ===
    if [[ "$line" == создать\ потолок* ]]; then
        POS=$(echo "$line" | grep -oP 'расположение \K[\d ]+')
        SIZE=$(echo "$line" | grep -oP 'размер \K[\d ]+')
        X=$(echo $POS | awk '{print $1}')
        Y=$(echo $POS | awk '{print $2}')
        W=$(echo $SIZE | awk '{print $1}')
        H=$(echo $SIZE | awk '{print $2}')
        echo "        // Потолок ($X, $Y) размером ($W x $H)" >> "$OUTPUT_FILE"
        continue
    fi

    # === ДВИГАТЬ КАМЕРУ ===
    if [[ "$line" == двигать\ камеру* ]]; then
        DX=$(echo "$line" | grep -oP 'по \K-?\d+' | head -1)
        DY=$(echo "$line" | grep -oP 'по \K-?\d+' | tail -1)
        [ -z "$DX" ] && DX=0
        [ -z "$DY" ] && DY=0
        echo "        cameraX += $DX; cameraY += $DY;" >> "$OUTPUT_FILE"
        continue
    fi

    # === ДВИГАТЬ ИГРОКА ===
    if [[ "$line" == двигать\ игрока* ]]; then
        DX=$(echo "$line" | grep -oP 'по \K-?\d+' | head -1)
        DY=$(echo "$line" | grep -oP 'по \K-?\d+' | tail -1)
        [ -z "$DX" ] && DX=0
        [ -z "$DY" ] && DY=0
        echo "        playerX += $DX; playerY += $DY;" >> "$OUTPUT_FILE"
        continue
    fi

    # === УСТАНОВИТЬ HP ===
    if [[ "$line" == установить\ hp* ]]; then
        HP=$(echo "$line" | grep -oP 'hp \K\d+')
        echo "        playerHP = $HP;" >> "$OUTPUT_FILE"
        continue
    fi

    # === УСТАНОВИТЬ ПАТРОНЫ ===
    if [[ "$line" == установить\ патроны* ]]; then
        AMMO=$(echo "$line" | grep -oP 'патроны \K\d+')
        echo "        playerAmmo = $AMMO;" >> "$OUTPUT_FILE"
        continue
    fi

    # === ЕСЛИ HP БОЛЬШЕ ===
    if [[ "$line" == если\ hp\ больше* ]]; then
        VAL=$(echo "$line" | grep -oP 'больше \K\d+')
        echo "        if (playerHP > $VAL) {" >> "$OUTPUT_FILE"
        continue
    fi

    # === ЗАКОНЧИТЬ ЕСЛИ ===
    if [[ "$line" == конец\ если* ]]; then
        echo "        }" >> "$OUTPUT_FILE"
        continue
    fi

    # === ЗАКОНЧИТЬ ПОКА ===
    if [[ "$line" == конец\ пока* ]]; then
        echo "        }" >> "$OUTPUT_FILE"
        continue
    fi

    # === НАЧАТЬ ИГРУ ===
    if [[ "$line" == начать\ игру* ]]; then
        echo "        // Начать игру" >> "$OUTPUT_FILE"
        continue
    fi

    # === ЗАВЕРШИТЬ ИГРУ ===
    if [[ "$line" == завершить\ игру* ]]; then
        echo "        System.exit(0);" >> "$OUTPUT_FILE"
        continue
    fi

    # === ПЕРЕЙТИ НА УРОВЕНЬ ===
    if [[ "$line" == перейти\ на\ уровень* ]]; then
        LVL=$(echo "$line" | grep -oP 'уровень \K\d+')
        echo "        // Переход на уровень $LVL" >> "$OUTPUT_FILE"
        continue
    fi

echo "Готово: $OUTPUT_FILE"
echo "=== Termux Compile завершён ==="
exit 0