package stx.stream;

using stx.Nano;
using stx.Test;

import stx.stream.test.WindowTest;

class Test{
  static public function main(){
    // stx.unit.Test.unit(__,
    //   [
    //     new WindowTest(),
    //   ],
    //   []
    //);
    var test = new WindowTest();
        test.test_history();
  }
}