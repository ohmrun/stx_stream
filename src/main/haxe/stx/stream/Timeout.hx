package stx.stream;

@:forward abstract Timeout(Future<Noise>){
  public function new(ms:Int=10){
    final ft    = Future.trigger();
    stx.pico.Delay.comply(() -> { ft.trigger(Noise);},ms);
    this = ft.asFuture();
  }
  public function prj():Future<Noise>{
    return this;
  }
}
private class Backoff{

}