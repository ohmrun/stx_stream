package stx.stream;

class Logging{
  static public function log(wildcard:Wildcard):Log{
    return 
      #if stx.stream.switches.debug
        __.log().tag(__.pkg());
      #else
        stx.Log.void();
      #end
  }
}