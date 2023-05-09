package stx.stream;

import tink.core.Future;

@:forward abstract Timeout(Future<Nada>){
  public function new(ms:Int=10){
    this = new Future(
      cb -> {
        final delay = stx.pico.Delay.comply(() -> { cb(Nada);},ms);
        return delay.cancel;
      }
    );
  }
  public function prj():Future<Nada>{
    return this;
  }
}
private class Backoff{

}