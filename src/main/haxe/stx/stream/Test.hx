package stx.stream;

using stx.Nano;
using stx.Test;

//import stx.stream.test.WindowTest;
import stx.stream.test.*;

class Test{
  static public function main(){
    __.test(
      [
        new Issue1(),
      ],
      []
    );
  }
}