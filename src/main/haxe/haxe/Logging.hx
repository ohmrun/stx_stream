package haxe;

using stx.Nano;
using stx.Log;
using stx.Pkg;

class Logging{
  static public function log(wildcard:Wildcard){
    return __.log().tag(__.pkg());
  }
}