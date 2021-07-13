package stx.stream.test;

class WindowTest extends TestCase{
  public function test_history(){
    var trigger = tink.core.Signal.trigger();
    var stream  = Stream.lift(trigger.asSignal());
        stream.handle(
          (x) -> {
            trace('all because I was here $x');
          }
        );
    var window  = stream.window();   
        window.handle(
          (x) -> {
            trace('all because I was here window $x');
          }
        );
    for(val in [1,2,3,4,5]){
      trigger.trigger(Val(val));
    }
        window.handle(
          (x) -> {
            trace('all because window $x');
          }
        );
        
  }
}