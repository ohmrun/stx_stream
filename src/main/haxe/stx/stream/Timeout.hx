package stx.stream;

@:forward abstract Timeout(Future<Noise>){
  public function new(ms:Int){
    final multiplier = 1.02;
    function step(time:Int){
      __.log().trace('timeout step: $time');
      time = Math.round(time * multiplier);
      return if(time > ms){
        ms;
      }else{
        time;
      }
    }
    this = new Future(
      (cb) -> {
        final start      = haxe.Timer.stamp();
        function is_finished(){
          return haxe.Timer.stamp() >= start + (ms/1000);
        }
        var cancelled    = false;
        var   next       = 200 > ms ? ms : 200;
        var   event      = null;
              event      = haxe.MainLoop.add(
                () -> {
                  __.log().trace('timeout tick. cancelled: $cancelled time $ms $next');
                  if(cancelled){
                    event.stop();
                  }else{
                    if(is_finished()){
                      cb(Noise);
                      event.stop();
                    }else{
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
}
private class Backoff{

}