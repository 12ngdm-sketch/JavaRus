import java.io.File;
import java.util.HashSet;
import java.util.Set;

public class main {
    
    static final String BASE_PATH = "/sdcard/проект javarus";
    static final String GAMES_PATH = BASE_PATH + "/здесь писать код/игры";
    static final String APPS_PATH = BASE_PATH + "/здесь писать код/приложения";
    static final String SPRITES_PATH = BASE_PATH + "/сюда картинки разрешение до 248";
    static final String COMPILE_PATH = BASE_PATH + "/здесь писать код/компилировать";
    static final String COMPILE_GAMES = COMPILE_PATH + "/игры";
    static final String COMPILE_APPS = COMPILE_PATH + "/приложение";
    
    static Set<String> knownFolders = new HashSet<>();
    
    public static void main(String[] args) {
        System.out.println("=== JavaRus Watcher v0.2 ===");
        System.out.println("Слежу за папками игр и приложений.");
        System.out.println("Нажми Ctrl+C, чтобы остановить.\n");
        
        // Создаём только то, чего не хватает (без дубликатов)
        ensureDir(GAMES_PATH);
        ensureDir(APPS_PATH);
        ensureDir(SPRITES_PATH);
        ensureDir(COMPILE_GAMES);
        ensureDir(COMPILE_APPS);
        
        // Запоминаем уже существующие папки в играх
        File gamesDir = new File(GAMES_PATH);
        File[] existing = gamesDir.listFiles();
        if (existing != null) {
            for (File f : existing) {
                if (f.isDirectory()) {
                    knownFolders.add(f.getName());
                    System.out.println("Уже есть игра: " + f.getName());
                }
            }
        }
        
        // Запоминаем уже существующие папки в приложениях
        File appsDir = new File(APPS_PATH);
        existing = appsDir.listFiles();
        if (existing != null) {
            for (File f : existing) {
                if (f.isDirectory()) {
                    knownFolders.add(f.getName());
                    System.out.println("Уже есть приложение: " + f.getName());
                }
            }
        }
        
        System.out.println();
        
        // Бесконечный цикл
        while (true) {
            checkForNewFolders();
            try {
                Thread.sleep(5000);
            } catch (InterruptedException e) {
                System.out.println("Наблюдение остановлено.");
                break;
            }
        }
    }
    
    // Создать папку, если её нет
    static void ensureDir(String path) {
        File dir = new File(path);
        if (!dir.exists()) {
            dir.mkdirs();
        }
    }
    
    // Проверка новых папок
    static void checkForNewFolders() {
        // Проверяем игры
        File gamesDir = new File(GAMES_PATH);
        File[] folders = gamesDir.listFiles();
        if (folders != null) {
            for (File folder : folders) {
                if (!folder.isDirectory()) continue;
                String name = folder.getName();
                if (!knownFolders.contains(name)) {
                    knownFolders.add(name);
                    System.out.println("\n=== НОВАЯ ИГРА: " + name + " ===");
                    createProjectStructure(name, false);
                }
            }
        }
        
        // Проверяем приложения
        File appsDir = new File(APPS_PATH);
        folders = appsDir.listFiles();
        if (folders != null) {
            for (File folder : folders) {
                if (!folder.isDirectory()) continue;
                String name = folder.getName();
                String key = "app_" + name;
                if (!knownFolders.contains(key)) {
                    knownFolders.add(key);
                    System.out.println("\n=== НОВОЕ ПРИЛОЖЕНИЕ: " + name + " ===");
                    createProjectStructure(name, true);
                }
            }
        }
    }
    
    // Создание структуры
    static void createProjectStructure(String name, boolean isApp) {
        String sourcePath = isApp ? APPS_PATH : GAMES_PATH;
        String compileTarget = isApp ? COMPILE_APPS : COMPILE_GAMES;
        
        // Папка для спрайтов (только если нет)
        File spriteDir = new File(SPRITES_PATH + "/" + name);
        if (!spriteDir.exists()) {
            spriteDir.mkdirs();
            System.out.println("Создана папка спрайтов: " + spriteDir.getPath());
        }
        
        // Файл .jrus
        File jrusFile = new File(sourcePath + "/" + name + "/" + name + ".jrus");
        if (!jrusFile.exists()) {
            try {
                jrusFile.createNewFile();
                System.out.println("Создан файл: " + jrusFile.getPath());
            } catch (Exception e) {
                System.out.println("Ошибка: " + e.getMessage());
            }
        }
        
        // Скрипт .sh
        File shFile = new File(compileTarget + "/" + name + ".sh");
        if (!shFile.exists()) {
            try {
                java.io.FileWriter writer = new java.io.FileWriter(shFile);
                writer.write("#!/bin/bash\n");
                writer.write("echo \"=== Сборка " + name + " ===\"\n");
                writer.write("cd \"" + BASE_PATH + "/компилятор\"\n");
                writer.write("./Termux_compile.sh " + name + "\n");
                writer.write("./Jvdroid_osnova " + name + "\n");
                writer.write("./pyromide_interface " + name + "\n");
                writer.write("./connection " + name + "\n");
                writer.write("./AndroidSDK_build " + name + "\n");
                writer.write("echo \"=== Готово! ===\"\n");
                writer.close();
                shFile.setExecutable(true);
                System.out.println("Создан скрипт: " + shFile.getPath());
            } catch (Exception e) {
                System.out.println("Ошибка: " + e.getMessage());
            }
        }
        
        System.out.println("=== ГОТОВО: " + name + " ===\n");
    }
}