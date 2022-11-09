package stx.stream;

#if target.threaded
@:keep class Thread{
  static function __init__(){
    get_main();
  }
  static public var main(get,null) : sys.thread.Thread;
  static public function get_main(){
    return main == null ? main = sys.thread.Thread.current() : main;
  }
}
#end