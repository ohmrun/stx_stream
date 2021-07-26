package stx.stream.test;

import tink.CoreApi;

using stx.Nano;
using stx.Log;

import stx.stream.Timeout;


class Issue1 extends stx.pico.Clazz{
  static public function main(){
    final logger = __.log().global;
          logger.includes.push("stx/stream");
          logger.level = TRACE;
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