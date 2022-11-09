package stx.stream.delay.term;

class Flash{
  public var done(default,null)      : Bool;

  private var cancelled : Bool;
  
  private var   id      : Null<Int>;

  private final op      : Void->Void;
  private final ms      : Int;
  

  public function new(op,ms){
    this.op         = op;
    this.ms         = ms;

    this.cancelled  = false;
    this.done       = false;
  }
  public function cancel(){
    this.cancelled = true;
  }
  public function start(){
    if(this.done){
      throw 'delay already called';
    }else{
      final me = this;
      id = untyped __global__["flash.utils.setInterval"](function() {
        untyped __global__["flash.utils.clearInterval"](id);
        if(!cancelled){
          this.done = true;
          me.op();
        }
      }, ms);
    }
  } 
}