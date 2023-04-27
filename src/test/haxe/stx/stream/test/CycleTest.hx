package stx.stream.test;

using stx.Pico;

@stx.test.async
class CycleTest extends TestCase{
  public function test(async:Async){
    final ft  = Future.trigger();

    final cyc = Cycle.anon(
      () -> {
        trace("ok");
        return ft.asFuture();    
      }
    );
    haxe.Timer.delay(
      () -> {
        ft.trigger(
          Cycle.unit()
        );
        async.done();
      },
      1000
    );
    cyc.submit();
  }
}