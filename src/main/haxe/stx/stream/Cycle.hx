package stx.stream;

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
  static public function lift(self:CycleDef):Cycle return Cycle.lift(self);

  static public function seq(self:Cycle,that:Cycle):Cycle{
    //trace('seq setup');
    return lift(
      () -> {
        return try{
          self().map(seq.bind(_,that));
        }catch(e:CYCLED){
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
    var event = null;
        event = haxe.MainLoop.add(
          () -> {
            try{
              self().handle(
                function rec(x:Cycle){
                  try{
                    x().handle(rec);
                  }catch(e:CYCLED){
                    event.stop();
                  }
                }
              );
            }catch(e:CYCLED){
              event.stop();
            }
          }
        );
  }
  static public function crunch(self:Cycle){
    //trace('crunching');
    try{
      self().handle(
        (x) -> {
          crunch(x);
        }
      );
    }catch(e:CYCLED){
      //trace("cycled");
    }catch(e:haxe.Exception){
      throw e;
    }
  }
}