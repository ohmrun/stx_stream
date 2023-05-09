package stx.stream;

class Logging{
  static public function log(wildcard:Wildcard):Log{
    return stx.Log.pkg(__.pkg());
      // #if (stx.stream.switches.debug=="true")
      //   stx.Log.pkg(__.pkg());
      // #else
      //   stx.Log.empty();
      // #end
  }
}