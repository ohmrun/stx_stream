package stx.stream.test;


class Logging{
  static public function log(wildcard:Wildcard){
    return stx.Log.pkg(__.pkg());
  }
}