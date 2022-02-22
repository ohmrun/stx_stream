package haxe;

using stx.Nano;
using stx.Log;
using stx.Pkg;

class Logging{
  static public function log(wildcard:Wildcard){
    return 
      #if stx.stream.switches.debug
        __.log().tag(__.pkg());
      #else
        __.log().void();
      #end
  }
}