package stx.stream;

using stx.Nano;
using stx.Test;
using stx.Log;

import stx.stream.test.*;

class Test{
  static public function main(){
    __.logger().global().configure(
          logger -> logger.with_logic(
            logic -> logic.or(
              logic.tags(["stx/stream"])
            )
          )
        );
    __.test().run(
      [
        new StreamTest(),
        new Issue1(),
        new CycleTest(),
        new RebuildTest()
      ],
      [RebuildTest]
    );
  }
}