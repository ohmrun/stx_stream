package stx.stream;

class Logging{
  static public function log(wildcard:Wildcard):Log{
    return 
      #if stx.stream.switches.debug
        stx.Log.pkg(__.pkg());
      #else
        stx.Log.empty();
      #end
  }
}