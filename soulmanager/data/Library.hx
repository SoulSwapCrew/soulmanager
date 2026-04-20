package soulmanager.data;

import soulmanager.Main;
import soulmanager.res.FileUtil;
import sys.FileSystem;
import sys.io.File;

using soulmanager.data.StringUtil;

class Library
{
	public var id:String = '';
	public var type:String = '';

	public function new(id:String)
	{
		this.id = id;
	}

	public function install() {}

	public function uninstall()
	{
		Sys.command('haxelib remove $id');
	}

	public function toString():String {
		return '$type';
	}
}

class Haxelib extends Library
{
	public var version:Null<String>;

	public function new(id:String, ?version:String)
	{
		super(id);

		this.type = 'haxelib';
		this.version = version;
	}

	override public function install()
	{
		super.install();

		// HMM-RS cheat
		File.saveContent('${Main.terminalPath}/hmm.json', '{"dependencies": []}');
		Sys.command('cd ${Main.terminalPath}');
		Sys.command('hmm-rs haxelib $id${version.addSpace()}');

		// We aren't gonna need this thing anymore!
		if (FileSystem.exists('${Main.terminalPath}/hmm.json')) {
			FileSystem.deleteFile('${Main.terminalPath}/hmm.json');
		}
	}

	override public function uninstall()
	{
		super.uninstall();
	}

	override public function toString():String {
		return '$type(version: ${version ?? 'latest'})';
	}
}

class Git extends Library
{
	public var url:String;
	public var branch:Null<String>;
	public var dir:Null<String>;

	public function new(id:String, url:String, ?branch:String, ?dir:String)
	{
		super(id);

		this.type = 'git';
		this.url = url;
		this.branch = branch;
		this.dir = dir;
	}

	override public function install()
	{
		super.install();

		// We now must cheat with HMM-RS until I can port the same solution here.
		File.saveContent('${Main.terminalPath}/hmm.json', '{"dependencies": []}');
		Sys.command('cd ${Main.terminalPath}');
		Sys.command('hmm-rs git $id${url.addSpace() + branch.addSpace()}');

		// We aren't gonna need this thing anymore!
		if (FileSystem.exists('${Main.terminalPath}/hmm.json')) {
			FileSystem.deleteFile('${Main.terminalPath}/hmm.json');
		}
	}

	override public function uninstall()
	{
		super.uninstall();
	}

	override public function toString():String {
		return '$type(url: $url, branch: $branch, dir: $dir)';
	}
}

class Dev extends Library
{
	public var path:String;

	public function new(id:String, path:String)
	{
		super(id);

		this.type = 'dev';
		this.path = path;
	}

	override public function install()
	{
		super.install();

		Sys.command('cd ${Main.terminalPath}');
		Sys.command('haxelib dev $id${path.addSpace()} --skip-dependencies');
	}

	override public function uninstall()
	{
		super.uninstall();
	}

	override public function toString():String {
		return '$type(path: $path)';
	}
}
