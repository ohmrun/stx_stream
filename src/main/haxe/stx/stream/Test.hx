package stx.stream;

using stx.Nano;
using stx.Test;

//import stx.stream.test.WindowTest;
import stx.stream.test.*;

class Test{
  static public function main(){
    // __.test(
    //   [
    //     new Issue1(),
    //   ],
    //   []
    // );
    trace('main');
    var a = new Timeout(100).prj();
    var b = new Timeout(3000).prj();
    var c = a.merge(b,(_,_) -> Noise);
        c.handle(
          (_) -> {
           trace("done");
          }
        );
    // var test = new WindowTest();
    //     test.test_history();
  }
}