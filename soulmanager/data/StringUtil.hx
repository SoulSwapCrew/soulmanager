package soulmanager.data;

class StringUtil
{
	public static function addSpace(str:String = ""):String
	{
		if (str == "")
			return str;

		return ' $str';
	}
}
