import java.io.File;
import java.util.Scanner;

public class Jvdroid_osnova {
    
    public static void main(String[] args) {
        System.out.println("=== Jvdroid Основа: проверка логики ===");
        
        if (args.length < 1) {
            System.out.println("Ошибка: не указано имя проекта");
            return;
        }
        
        String name = args[0];
        String base = "/sdcard/проект javarus";
        String javaFile = base + "/temp/" + name + ".java";
        
        File file = new File(javaFile);
        if (!file.exists()) {
            System.out.println("Ошибка: файл " + javaFile + " не найден");
            return;
        }
        
        try {
            Scanner scanner = new Scanner(file);
            boolean hasClass = false;
            boolean hasMain = false;
            
            while (scanner.hasNextLine()) {
                String line = scanner.nextLine();
                if (line.contains("public class")) hasClass = true;
                if (line.contains("public static void main")) hasMain = true;
            }
            scanner.close();
            
            if (hasClass && hasMain) {
                System.out.println("Логика в порядке. Отправляю в соединение...");
                File mergeFlag = new File(base + "/temp/" + name + ".logic_ok");
                mergeFlag.createNewFile();
                System.out.println("Флаг создан: " + mergeFlag.getPath());
            } else {
                System.out.println("ВЫ НЕ ПРАВИЛЬНО НАПИСАЛИ КОД");
                System.out.println("ПЕРЕПИШИТЕ КОД И ПОПРОБУЙТЕ ЕЩЁ РАЗ");
            }
            
        } catch (Exception e) {
            System.out.println("Ошибка: " + e.getMessage());
        }
    }
}