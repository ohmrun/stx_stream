package stx.stream.delay.term;

class Javascript{
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
      id = untyped setInterva(function() {
        if(!cancelled){ 
          this.done = true;
          me.op();
        }
      }, ms);
    }
  } 
}
