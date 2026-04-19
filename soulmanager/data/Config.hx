package soulmanager.data;

import sys.FileSystem;
import sys.io.File;
import soulmanager.data.Library;
import haxe.Json;

class Profile {
    public var id:String;
    public var libraries:Array<Library> = [];

    public function new(id:String, libraries:Array<Library>) {
        this.id = id;
        this.libraries = libraries;
    }

    public function addLibrary(library:Library) {
        for (lib in libraries) {
            if (lib.id != library.id) continue;
            libraries.remove(lib);
        }

        libraries.push(library);
    }
}

class Config {
    public var profiles:Array<Profile> = [];

    public function new() {}

    public static function check():Bool {
        return FileSystem.exists('${Main.terminalPath}/soulmanagerconfig.json');
    }

    public function getProfile(id:String):Profile {
        for (prof in profiles) {
            if (prof.id != id) continue;

            return prof;
        }

        return null;
    }

    public function addProfile(id:String) {
        for (prof in profiles) {
            if (prof.id != id) continue;

            return;
        }

        profiles.push(new Profile(id, []));
    }

    public function removeProfile(id:String) {
        profiles.remove(getProfile(id));
    }

    public static function defaultConfig():Config {
        if (check()) {
            return load();
        }

        var conf = new Config();

        if (conf.profiles.length == 0)
            conf.profiles.push(new Profile('default', []));

        conf.save();

        return conf;
    }

    public static function load():Config {
        final path:String = '${Main.terminalPath}/soulmanagerconfig.json';

        var cont = Json.parse(File.getContent(path));
        var config = new Config();

        for (i in 0... cont.profiles.length) {
            var prof = cont.profiles[i];
            var libs:Array<Library> = [];

            var data:Array<Dynamic> = cast prof.libraries;
            for (lib in data) {
                switch (lib.type) {
                    case 'haxelib':
                        libs.push(new Haxelib(lib.id, lib?.version));

                    case 'git':
                        libs.push(new Git(lib.id, lib.url, lib?.branch, lib?.dir));

                    case 'dev':
                        libs.push(new Dev(lib.id, lib.path));
                }
            }

            config.profiles.push(new Profile(prof.id, libs));
        }

        if (config.profiles.length == 0)
            config.profiles.push(new Profile('default', []));

        return config;
    }

    public function save() {
        var daStruct = {
            profiles: []
        };

        for (prof in profiles) {
            daStruct.profiles.push({
                id: prof.id,
                libraries: prof.libraries
            });
        }

        if (daStruct.profiles.length == 0) {
            var prof = new Profile('default', []);

            daStruct.profiles.push({
                id: prof.id,
                libraries: prof.libraries
            });
        }

        File.saveContent('${Main.terminalPath}/soulmanagerconfig.json', Json.stringify(daStruct, null, '    '));
    }
}