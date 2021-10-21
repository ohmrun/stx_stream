package stx.stream;

class Logging{
  static public function log(wildcard:Wildcard){
    return stx.Log.pkg(__.pkg());
  }
  static public function syslog(wildcard:Wildcard){
    return new stx.Log().tag("stx/stream/DEBUG");
  }
}