package soulmanager;

import haxe.Http;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.crypto.Md5;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.Path;
import soulmanager.data.Config;
import soulmanager.data.Library.Dev;
import soulmanager.data.Library;
import soulmanager.res.FileUtil;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Main
{
	public static var terminalPath:String = '.';
	public static var profile(get, never):String;

	static function get_profile():String
	{
		return File.getContent('$terminalPath/.haxelib/.currentProfile');
	}

	static function main()
	{
		var args:Array<String> = Sys.args();
		terminalPath = args.pop();

		// This forces terminalPath to be "./" when we actually use it
		// in the code.
		if (terminalPath == '')
			terminalPath = '.';

		Sys.println('- SOULMANAGER -');

		#if setup
		args = ['setup'];
		#end

		switch (args[0])
		{
			default:
				Sys.println(sys.io.File.getContent('./soulmanager/res/helpDialogue.txt'));

			case 'setup':
				setupAlias('soulmanager', 'haxelib --global run soulmanager');

			case 'haxelib':
				checkHaxelibFolder();

				var config = Config.defaultConfig();
				config.getProfile(profile).addLibrary(new Haxelib(args[1], args[2]));
				config.save();

			case 'git':
				checkHaxelibFolder();

				var config = Config.defaultConfig();
				config.getProfile(profile).addLibrary(new Git(args[1], args[2], args[3], args[4]));
				config.save();

			case 'dev':
				checkHaxelibFolder();

				var config = Config.defaultConfig();
				config.getProfile(profile).addLibrary(new Dev(args[1], args[2]));
				config.save();

			case 'install':
				installLibs();

			case 'profile':
				switch(args[1]) {
					case 'switch':
						switchProfile(args[2]);

					case 'add':
						var config = Config.defaultConfig();
						config.addProfile(args[2]);
						config.save();

					case 'remove':
						var config = Config.defaultConfig();
						config.removeProfile(args[2]);
						config.save();
				}

			case 'list':
				Sys.println('Retrieving libraries...');
				var config = Config.defaultConfig();
				for (profile in config.profiles) {
					Sys.println('\n- ${profile.id} -');
					for (library in profile.libraries) {
						Sys.println('${library.id}: ${library.toString()}');
					}
				}

			case 'sfl':
				var oldProfile:String = profile;
				stealFunkinLibs();
				switchProfile(oldProfile);

			case 'clear':
				if (FileSystem.exists('$terminalPath/.haxelib')) {
					var config = Config.defaultConfig();

					if (args[1] == '-config') {
						config.getProfile(profile).libraries.resize(0);
					}

					Sys.println('Retrieving libraries...');

					final oldProfile:String = profile;

					Sys.command('cd $terminalPath');
					Sys.command('hmm-rs clean');

					switchProfile(oldProfile);

					Sys.command('cd ./');

					Sys.println("Cleared haxelibs successfully!");
				} else
					Sys.println("There's nothing to clear!");
		}

		Sys.println('\nFixing repository...');
		Sys.command('haxelib fixrepo');
		Sys.println('\nDone!');

		Sys.exit(1);
	}

	public static function installLibs() {
		checkHaxelibFolder();

		// We now must cheat with HMM-RS until I can port the same solution here.
		File.saveContent('${Main.terminalPath}/hmm.json', '{"dependencies": []}');
		Sys.command('cd ${Main.terminalPath}');

		var config = Config.defaultConfig();
		for (library in config.getProfile(profile).libraries) {
			library.install();
		}

		// We aren't gonna need this thing anymore!
		if (FileSystem.exists('${Main.terminalPath}/hmm.json')) {
			FileSystem.deleteFile('${Main.terminalPath}/hmm.json');
		}

		Sys.command('cd ./');
	}

	public static function checkHaxelibFolder()
	{
		if (!FileSystem.exists('$terminalPath/.haxelib'))
			Sys.command('haxelib newrepo');

		if (!FileSystem.exists('$terminalPath/.haxelib/.currentProfile'))
			switchProfile('default');
	}

	public static function switchProfile(id:String)
	{
		if (FileSystem.exists('$terminalPath/.haxelib/.currentProfile'))
			FileSystem.deleteFile('$terminalPath/.haxelib/.currentProfile');
		else
		{
			FileSystem.createDirectory('$terminalPath/.haxelib');
		}

		File.saveContent('$terminalPath/.haxelib/.currentProfile', id);
	}

	static function stealFunkinLibs()
	{
		if (FileSystem.exists('$terminalPath/hmm.json')) {
			FileSystem.deleteFile('$terminalPath/hmm.json');
		}

		// Reset export folder
		final HMM_DATA:String = Http.requestUrl('https://raw.githubusercontent.com/FunkinCrew/Funkin/develop/hmm.json');
		final HMM_JSON:Dynamic = cast Json.parse(HMM_DATA);

		var my_hmm:Dynamic = {
			dependencies: []
		};

		for (i in 0...HMM_JSON.dependencies.length)
		{
			var haxelib:Dynamic = HMM_JSON.dependencies[i];

			for (field in Reflect.fields(haxelib))
			{
				if (!Reflect.hasField(haxelib, field))
					Reflect.setProperty(haxelib, field, null);
			}

			my_hmm.dependencies.push(haxelib);
		}

		//File.saveContent('$terminalPath/hmm.json', Json.stringify(my_hmm, null, '  '));

		switchProfile('funkin');
		var config = Config.defaultConfig();

		var profile = config.getProfile('funkin');
		for (i in 0... my_hmm.dependencies.length) {
			var library = my_hmm.dependencies[i];
			profile.addLibrary(hmmToSoul(library));
		}

		config.save();

		Sys.println('Stolen Funkin\' libs successfully!');
	}

	static function hmmToSoul(hmm:Dynamic):Library {
		switch(hmm.type) {
			case 'haxelib':
				return new Haxelib(hmm.name, hmm.version);

			case 'git':
				return new Git(hmm.name, hmm.url, hmm?.ref, hmm?.dir);

			case 'dev':
				return new Dev(hmm.name, hmm?.path);
		}

		return null;
	}

	static function setupAlias(alias:String, cmd:String):Void
	{
		var sysName = Sys.systemName().toLowerCase();
		try
		{
			if (sysName.contains('window'))
			{
				var haxePath:String = Sys.getEnv('HAXEPATH').trim();
				if (haxePath == null || haxePath == '')
					haxePath = 'C:\\HaxeToolkit\\haxe';

				File.saveContent(Path.join([haxePath, '$alias.bat']), '@echo off\n$cmd %*');
			}
			else if (sysName.contains('linux') || sysName.contains('mac'))
			{
				var sudoName:String = sysName.contains('mac') ? '' : 'sudo ';

				Sys.command('${sudoName}cp -f ${Path.join([Sys.getCwd(), '$alias.sh'])} ${Path.join(["/usr/local/bin", '$alias'])}');
				Sys.command('${sudoName}chmod 775 ${Path.join(["/usr/local/bin", '$alias'])}');
			}
			else
			{
				Sys.println('Installing the command line alias is not supported on this OS');
				return;
			}

			// THANK YOU CYN
			Sys.println('Installed command-line alias "$alias" for "$cmd"');
		}
		catch (e)
		{
			Sys.println('Failed to install command-line alias');
			return;
		}
	}
}
