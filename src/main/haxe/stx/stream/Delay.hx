package stx.stream;

class Delay extends 
  #if flash
    stx.stream.delay.term.Flash
  #elseif js
    stx.stream.delay.term.Javascript
  #elseif target.threaded
    stx.stream.delay.term.Threaded
  #else
    stx.stream.delay.term.Ignore
  #end
{
  static public function comply(op,ms):Delay{
    trace('comply');
    final delay = new Delay(op,ms);
          delay.start();
    return delay;
  }
}