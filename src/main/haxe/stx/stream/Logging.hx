package stx.stream;

class Logging{
  static public function log(wildcard:Wildcard){
    return stx.Log.pkg(__.pkg());
  }
}