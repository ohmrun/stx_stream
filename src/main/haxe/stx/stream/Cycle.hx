package stx.stream;

import hx.concurrent.executor.*;

enum CYCLED{
  CYCLED;
}
typedef CycleDef = Thunk<Future<Cycle>>;

@:using(stx.stream.Cycle.CycleLift)
@:callable abstract Cycle(CycleDef) from CycleDef to CycleDef{
  public function new(self:CycleDef) this = self;
  static public function lift(self:CycleDef):Cycle{
    return new Cycle(self);
  }
  static public var ZERO = unit();

  static public function unit():Cycle{
    return lift(() -> {
      throw CYCLED;
      return unit();
    });
  }
  @:from static public function fromFutureCycle(self:Future<Cycle>):Cycle{
    return lift(() -> self);
  }
  @:from static public function fromWork(self:Work):Cycle{
    return self.prj().fold(
      (ok) -> lift(() -> ok),
      ()   -> ZERO
    );
  }

}
class CycleLift{
  static public var EXECUTOR(get,null):Executor;
  static public function get_EXECUTOR(){
    return __.option(EXECUTOR).def(() -> EXECUTOR = Executor.create(3));
  }
  static public function lift(self:CycleDef):Cycle return Cycle.lift(self);

  static public function seq(self:Cycle,that:Cycle):Cycle{
    __.log().trace('seq setup');
    return lift(
      () -> {
        __.log().trace('seq call');
        return try{
          final next = self();
          __.log().trace('$next');
          next.map(seq.bind(_,that));
        }catch(e:CYCLED){
          __.log().trace('seq:that $that');
          that;
        };
      } 
    );
  }
  static public function par(self:Cycle,that:Cycle):Cycle{
    return lift(
      () -> {
        var l = None;
        var r = None;
        try{
          l = Some(self());
        }catch(e:CYCLED){}
        
        try{
          r = Some(that());
        }catch(e:CYCLED){}
        
        return switch([l,r]){
          case [Some(l),Some(r)]  : lift(() -> Future.inParallel([l,r]).map(
            arr -> par(arr[0],arr[1])
          ));
          case [Some(l),None]     : l;
          case [None,Some(r)]     : r;
          case [None,None]        : Cycle.ZERO(); 
        }
      }
    );
  }
  static public function submit(self:Cycle){
    __.log().trace('cycle/submit');
    var report = __.report();
    function catcher(fn){
      try{
        fn();
      }catch(err:Err<Dynamic>){
        report = err.report();  
      }catch(e:Dynamic){
        report = __.report(f -> f.any('$e'));
      }
    }
    EXECUTOR.submit(
      () -> {
        try{
          __.log().trace('cycle:call');
          self().handle(
            function rec(x:Cycle){
              catcher(
                () -> {
                  try{
                    __.log().trace('cycle:loop');
                    final next = x();
                    __.log().trace('cycle:loop:next $next');
                    next.handle(
                      (x) -> {
                        EXECUTOR.submit(rec.bind(x),ONCE(0));
                      }
                    );
                  }catch(e:CYCLED){
                    __.log().trace('cycle:stop');
                  }
                }
              );
            }
          );
        }catch(e:CYCLED){
          __.log().trace('cycle:stop');
        }
      },
      ONCE(0)
    );
  }
  static public function crunch(self:Cycle){
    __.log().trace('crunching');
    try{
      self().handle(
        (x) -> {
          crunch(x);
        }
      );
    }catch(e:CYCLED){
      __.log().trace("cycled");
    }catch(e:haxe.Exception){
      throw e;
    }
  }
}
// class FutureScheduled<T> implements hx.concurrent.Future<T> {

//   public var result(default, null):Null<FutureResult<T>>;

//   public var onResult(default, set):(FutureResult<T>) -> Void;
//   inline function set_onResult(fn:(FutureResult<T>) -> Void) {
//      // immediately invoke the callback function in case a result is already present
//      if (fn != null) {
//         final result = this.result;
//         switch(result) {
//            case NONE(_):
//            default: fn(result);
//         }
//      }
//      return onResult = fn;
//   }

//   function new(ft:Future<T>) {
//      onResult = null;
//      result = FutureResult.NONE(this);
//   }
// }