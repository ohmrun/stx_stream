package stx.stream.delay.term;

import tink.RunLoop;
#if target.threaded
  import sys.thread.Thread in HThread;
  import stx.stream.Thread;

  typedef Milliseconds  = Int;
  typedef Seconds       = Float;

  class Threaded{
    static public var pool(get,null) : sys.thread.ElasticThreadPool;
    static public function get_pool(){
      return pool == null ? pool = new sys.thread.ElasticThreadPool(30) : pool; 
    }

    public var done(default,null)       : Bool;
    private var cancelled               : Bool;

    private final op                    : Void->Void;
    private final ms                    : Int;

    public function new(op,ms){
      this.op       = op;
      this.ms       = ms;

      this.done      = false;
      this.cancelled = false; 
    }
    public function cancel(){
      this.cancelled = true;
    }
    public function start(){
      __.log().trace('start');

      final cb = RunLoop.current.bind(
        (cb) -> {
          __.log().trace('done');
        }
      );
      run(cb);
    }
    private function run(cb){
      __.log().trace('run');
      pool.run(
        () -> {
          __.log().trace('running');
          if(done){
            throw 'delay already called';     
          }else{
            __.log().trace('waiting');
            Sys.sleep(ms / 1000);
            __.log().trace('waited');
            done = true;
            if(!cancelled){
              op();
            }
            __.log().trace('ready');
            cb(Noise);
          }
        }
      );
    }
  }
#end