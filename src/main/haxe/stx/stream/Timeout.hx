package stx.stream;

@:forward abstract Timeout(Future<Noise>){
  public function new(ms:Int){
    final id = __.uuid('xxxx');
    __.log().trace('timeout#$id: $ms');
    final multiplier = 1.01;
    function step(time:Int){
      return Math.round(time * multiplier);
    }
    this = new Future(
      (cb) -> {
        final start      = haxe.Timer.stamp();
        function exit_time(){
          return start + (ms/1000);
        }
        function is_finished(){
          return haxe.Timer.stamp() >= exit_time();
        }
        function since(){
          return haxe.Timer.stamp() - start;
        }
        var cancelled    = false;
        var   next       = 200 > ms ? ms : 200;
        var   event      = null;
              event      = haxe.MainLoop.add(
                () -> {
                  __.log().trace('timeout#${id} tick. cancelled: $cancelled time ${since()}');
                  if(cancelled){
                    event.stop();
                  }else{
                    __.log().trace('$id finished?${is_finished()}');
                    if(is_finished()){
                      __.log().trace('$id COMPLETE');
                      event.stop();
                      cb(Noise);
                    }else{
                      __.log().trace('$id CONTINUE');
                      next = step(next);
                      event.delay(next/1000);
                    }
                  }
                }
              );
        return () -> {
          cancelled = true;
        } 
      }
    );
  }
  public function prj():Future<Noise>{
    return this;
  }
}
private class Backoff{

}