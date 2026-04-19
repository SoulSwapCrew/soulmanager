package soulmanager.res;

import haxe.io.Path;
import sys.FileSystem;

class FileUtil {
    inline public static function deleteAllFilesInDirectory(dir:String) {
        for (file in search(dir)) {
            FileSystem.deleteFile(file);
        }
    }

    inline public static function deleteDirectory(dir:String) {
        deleteAllFilesInDirectory(dir);
        
        for (d in searchForDirectories(dir))
            FileSystem.deleteDirectory(d);
    }

    inline public static function createDirectory(dir:String) {
        FileSystem.createDirectory(dir);
    }

    public static function search(dir:String):Array<String> {
        var arr:Array<String> = [];
        if (!FileSystem.exists(dir)) return arr;

        for (file in FileSystem.readDirectory(dir)) {
            final _file:String = Path.join([dir, file]);
            if (!FileSystem.exists(_file)) continue;

            if (FileSystem.isDirectory(_file))
                for (otherFile in search(_file))
                    arr.push(otherFile);
            else
                arr.push(_file);
        }
        return arr;
    }

    public static function searchForDirectories(dir:String):Array<String> {
        var arr:Array<String> = [dir];
        if (!FileSystem.exists(dir)) return arr;

        for (file in FileSystem.readDirectory(dir)) {
            final _file:String = Path.join([dir, file]);
            if (!FileSystem.exists(_file)) continue;

            if (FileSystem.isDirectory(_file)) {
                for (d in searchForDirectories(_file))
                    arr.push(d);
            }
        }

        // Sort the array based on amount of subdirectories,
        // so that we always get the last subdirectory within each directory.
        arr.sort((f1, f2) -> {
            return f2.split('/').length - f1.split('/').length;
        });

        return arr;
    }
}