package stx.stream.test;


@stx.test.async
class RebuildTest extends TestCase{
  public function test_seq(async:Async){
    Cycle.anon(
      () -> {
        final next = Bang.unit();
        haxe.Timer.delay(
          () -> {
            next.fill(
              Cycle.anon(
                () -> {
                  async.done();
                  return Cycle.unit();
                }
              )
            );
          },
          10
        );
        return next.toWork().toCycle();
      }
    ).submit();
  }
}