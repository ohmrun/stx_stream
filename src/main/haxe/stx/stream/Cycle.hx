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
    __.log().info('cycle/submit');
    var event : haxe.MainLoop.MainEvent = null;
        event = haxe.MainLoop.add(
          () -> {
            try{
              __.log().trace('cycle:call');
              self().handle(
                function rec(x:Cycle){
                  try{
                    __.log().trace('cycle:loop');
                    final next = x();
                    __.log().trace('cycle:loop:next $next');
                    next.handle(rec);
                  }catch(e:CYCLED){
                    __.log().trace('cycle:stop');
                    //event.isBlocking            = false;
                    //@:privateAccess event.next  = null;      
                    event.stop();
                    final has_events = haxe.MainLoop.hasEvents();
                    __.log().debug('has_events $has_events $event');

                    final pending   = @:privateAccess haxe.EntryPoint.pending.length;
                    __.log().debug('has_pending $pending');

                    final thread_count = @:privateAccess haxe.EntryPoint.threadCount;

                    __.log().debug('has_pending $thread_count');
                    
                  }catch(e:Dynamic){
                    __.log().trace('cycle:quit $e');
                    event.stop();
                    haxe.MainLoop.runInMainThread(
                      () -> {
                        throw(e);
                      }
                    );
                  }
                }
              );
            }catch(e:CYCLED){
              __.log().trace('cycle:stop');
              event.stop();
            }catch(e:Dynamic){
              __.log().trace('cycle:quit $e');
              haxe.MainLoop.runInMainThread(
                () -> {
                  throw(e);
                }
              );
            }
          }
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