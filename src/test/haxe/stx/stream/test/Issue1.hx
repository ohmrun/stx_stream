package stx.stream.test;

import tink.CoreApi;

using stx.Nano;
using stx.Log;

import stx.stream.Timeout;


class Issue1 extends TestCase{
  static public function main(){
    __.logger().global().configure(
      logger -> logger.with_logic(
        logic -> logic.or(
          logic.tags(["stx/stream"])
        )
      ) 
    );
    trace('main');
    var self = new Issue1();
        self.test();
  }
  public function test(){
    var a = new Timeout(100).prj();
    var b = new Timeout(2000).prj();
    var c = a.merge(b,(_,_) -> Noise);
        c.handle(
          (_) -> {
            trace('done');
          }
        );
  }
}