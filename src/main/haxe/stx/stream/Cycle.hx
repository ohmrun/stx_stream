package stx.stream;

enum CYCLED{
  CYCLED;
}
typedef CycleDef = () -> Future<Cycle>;

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
      throw CYCLED;
      return unit();
    });
  }
  @:from static public function fromFutureCycle(self:Future<Cycle>):Cycle{
    return lift(
      () -> {
        __.assert().exists(self);
        return self;
      }  
    );
  }
  @:from static public function fromWork(self:Work):Cycle{
    return self.prj().fold(
      (ok) -> lift(() -> ok),
      ()   -> ZERO
    );
  }

}
class CycleLift{
  static public function lift(self:CycleDef):Cycle return @:privateAccess Cycle.lift(self);

  static public function seq(self:Cycle,that:Cycle):Cycle{
    __.assert().exists(self);
    __.assert().exists(that);
    __.log().blank('seq setup');
    return lift(
      () -> {
        __.log().blank('seq call');
        return try{
          final next = self();
          __.assert().exists(next);
          __.log().blank('$next');
          next.map(seq.bind(_,that));
        }catch(e:CYCLED){
          __.log().blank('seq:that $that');
          that;
        };
      } 
    );
  }
  static public function par(self:Cycle,that:Cycle):Cycle{
    __.assert().exists(self);
    __.assert().exists(that);
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
              __.log().blank('cycle:call');
              self().handle(
                function rec(x:Cycle){
                  try{
                    __.log().blank('cycle:loop');
                    final next = x();
                    __.log().blank('cycle:loop:next $next');
                    next.handle(rec);
                  }catch(e:CYCLED){
                    __.log().blank('cycle:stop');
                    event.stop();
                    final has_events = haxe.MainLoop.hasEvents();
                    __.log().blank('has_events $has_events $event');

                    final pending   = @:privateAccess haxe.EntryPoint.pending.length;
                    __.log().blank('has_pending $pending');

                    final thread_count = @:privateAccess haxe.EntryPoint.threadCount;

                    __.log().blank('thread count $thread_count');
                    
                  }catch(e:Dynamic){
                    __.log().fatal('cycle:quit $e');
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
              __.log().fatal('cycle:stop');
              event.stop();
            }catch(e:Dynamic){
              __.log().fatal('cycle:quit $e');
              haxe.MainLoop.runInMainThread(
                () -> {
                  throw(e);
                }
              );
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
            result.handle(
              x -> { 
                __.log().blank('crunching:handled');    
                self = x;
               }
            );
            __.log().blank("crunch:handle_called");
          }catch(e:CYCLED){
            __.log().blank("cycled");
            cont = false;
            break;
          }catch(e:haxe.Exception){
            __.log().fatal(e.toString());
            throw e;
          }
          __.assert().exists(self);
        }else{
          break;
          //throw 'Cycle handed null to run';
        }
      }
    }
    inner(self);
  }
}