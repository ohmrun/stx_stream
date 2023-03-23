package stx.stream;

import tink.core.Future;
import tink.core.Noise;

@:forward abstract Timeout(Future<Noise>){
  public function new(ms:Int=10){
    this = new Future(
      cb -> {
        final delay = stx.pico.Delay.comply(() -> { cb(Noise);},ms);
        return delay.cancel;
      }
    );
  }
  public function prj():Future<Noise>{
    return this;
  }
}
private class Backoff{

}