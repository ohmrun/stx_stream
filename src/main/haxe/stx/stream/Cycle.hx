package stx.stream;

enum CYCLED{
  CYCLED;
}
enum abstract CycleState(UInt){
  var CYCLE_STOP = 0;
  var CYCLE_NEXT = 1;
}
typedef CycleDef = () -> Couple<CycleState,Null<Future<Cycle>>>;

@:using(stx.stream.Cycle.CycleLift)
@:callable abstract Cycle(CycleDef) from CycleDef to CycleDef{
  public function new(self:CycleDef) {
    __.assert().exists(self);
    this = self;
  }
  static private function lift(self:CycleDef):Cycle{
    __.assert().exists(self);
    return new Cycle(self);
  }
  static public var ZERO(get,null) : Cycle;
  static private function get_ZERO(){
    return ZERO == null  ? ZERO = unit() : ZERO;
  }
  static public function unit():Cycle{
    return lift(() -> {
      return __.couple(CYCLE_STOP,null);
    });
  }
  @:from static public function fromFutureCycle(self:Future<Cycle>):Cycle{
    return lift(
      () -> {
        __.assert().exists(self);
        return __.couple(CYCLE_NEXT,self);
      }  
    );
  }
  @:from static public function fromWork(self:Work):Cycle{
    return self.prj().fold(
      (ok) -> lift(() -> __.couple(CYCLE_NEXT,Future.irreversible(cb -> cb(ok)))),
      ()   -> ZERO
    );
  }

}
class CycleLift{
  static public function lift(self:CycleDef):Cycle return @:privateAccess Cycle.lift(self);

  static public function seq(self:Cycle,that:Cycle):Cycle{
    #if debug
    __.assert().exists(self);
    __.assert().exists(that);
    __.log().trace('seq setup');
    #end
    return lift(
      () -> {
        #if debug
        __.log().trace('seq called');
        #end
        return self().decouple(
          (i,n) -> switch(i){
            case CYCLE_NEXT : __.couple(CYCLE_NEXT,n.map(seq.bind(_,that)));
            case CYCLE_STOP : __.couple(CYCLE_NEXT,Future.irreversible(cb -> cb(that)));
          }
        ); 
      }
    );
  }
  static public function par(self:Cycle,that:Cycle):Cycle{
    #if debug
    __.assert().exists(self);
    __.assert().exists(that);
    #end
    return lift(
      () -> {
        var l = self();
        var r = self();
        return switch([l.tup(),r.tup()]){
          case [tuple2(CYCLE_STOP,_),tuple2(CYCLE_STOP,_)] : __.couple(CYCLE_STOP,null);
          case [tuple2(CYCLE_NEXT,n),tuple2(CYCLE_STOP,_)] : __.couple(CYCLE_NEXT,n);
          case [tuple2(CYCLE_STOP,_),tuple2(CYCLE_NEXT,n)] : __.couple(CYCLE_NEXT,n);
          case [tuple2(CYCLE_NEXT,a),tuple2(CYCLE_NEXT,b)] : __.couple(CYCLE_NEXT,a.merge(b,seq));
        }
      }
    );
  }
  static public function submit(self:Cycle){
    __.log().info('cycle/submit');
    var event : haxe.MainLoop.MainEvent = null;
        event = haxe.MainLoop.add(
          () -> {
            //__.log().trace('tick');
            if(self != null){
              try{
                var next = self;
                self = null;
                next().decouple(
                  (code,next) -> switch(code){
                    case CYCLE_STOP : 
                      event.stop();
                    case CYCLE_NEXT :
                      //__.log().trace('next');
                      next.handle(
                        x -> {
                          self = x;
                        }
                      );  
                  }
                );
              }catch(e:Dynamic){
                event.stop();
                haxe.MainLoop.runInMainThread(
                  () -> {
                    throw(e);
                  }
                );
              }
            }
          }
        );
  }
  //TODO backoff algo
  static public function crunch(self:Cycle){
    __.assert().exists(self);
    __.log().info('cycle/crunch');
    
    function inner(self:Cycle){
      var cont = true;
      while(cont){
        __.log().blank('$cont $self');
        if(self!=null){
          __.log().blank('crunching:call');    
          final call = self;
          self = null;
          try{
            final result = call();
            __.assert().exists(result);
            result.decouple(
              (code,next) -> {
                switch(code) {
                  case CYCLE_STOP : 
                    cont = false;
                    null;
                  case CYCLE_NEXT :
                    next.handle(
                      x -> self = x
                    );
                    null;
                }
              }
            );
          }
        }
      }
    }
    inner(self);
  }
}