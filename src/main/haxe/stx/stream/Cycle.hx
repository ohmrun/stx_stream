package stx.stream;

enum CYCLED{
  CYCLED;
}
enum abstract CycleState(UInt){
  var CYCLE_STOP = 0;
  var CYCLE_NEXT = 1;
}
interface CyclerApi{
  public var state(get,null)          : CycleState;
  public function get_state()         : CycleState;
  
  public var value(get,null)          : Null<Future<Cycle>>;
  public function get_value()         : Null<Future<Cycle>>;

  public function toString():String;
  public function toCyclerApi():CyclerApi;
}
abstract class CyclerCls implements CyclerApi{
  public var state(get,null)            : CycleState;
  abstract public function get_state()  : CycleState;

  public var value(get,null)            : Null<Future<Cycle>>;
  abstract public function get_value()  : Null<Future<Cycle>>;

  public inline function toString(){
    return 'Cycler($state:$value)';
  } 
  public function toCyclerApi():CyclerApi{
    return this;
  }
}
class AnonCyclerCls extends CyclerCls{
  final method : Void -> Future<Cycle>;
  public function new(method){
    this.method = method.cache();
  }
  public function get_value(){
    return this.method();
  }
  public function get_state(){
    return this.value == null ? CYCLE_STOP : CYCLE_NEXT;
  }
}
class UnitCyclerCls extends CyclerCls{
  public function new(){}
  public function get_value(){
    return null;
  }
  public function get_state(){
    return CYCLE_STOP;
  }
}
class PureCyclerCls extends CyclerCls{
  public function new(value){
    this.value = value;
  }
  public function get_value(){
    return value;
  }
  public function get_state(){
    return CYCLE_NEXT;
  }
}
@:forward abstract Cycler(CyclerApi) from CyclerApi to CyclerApi{
  public function new(self) this = self;
  static public inline function lift(self:CyclerApi):Cycler return new Cycler(self);

  public function prj():CyclerApi return this;
  private var self(get,never):Cycler;
  private function get_self():Cycler return lift(this);

  static public inline function unit(){
    return lift(new UnitCyclerCls());
  }
  @:from static public inline function fromFuture(f:Future<Cycle>){
    return lift(new PureCyclerCls(f));
  }
  static public inline function pure(f:Future<Cycle>):Cycler{
    return lift(new PureCyclerCls(f));
  }
  @:to public function toCycle(){
    return new Cycle(this);
  }
}
@:using(stx.stream.Cycle.CycleLift)
@:forward(toCyclerApi) abstract Cycle(CyclerApi) from CyclerApi to CyclerApi{
  public function new(self:CyclerApi) {
    //__.assert().exists(self);
    this = self;
  }
  static private inline function lift(self:CyclerApi):Cycle{
    //__.assert().exists(self);
    return new Cycle(self);
  }
  static public var ZERO(get,null) : Cycle;
  static private inline function get_ZERO():Cycle{
    return ZERO == null ? ZERO = unit() : ZERO;
  }
  static public inline function unit():Cycle{
    return lift(Cycler.unit());
  }
  @:from static public inline function fromFutureCycle(self:Future<Cycle>):Cycle{
    return lift(
      Cycler.pure(self)
    );
  }
@:from static public function fromWork(self:Work):Cycle{
    return self.is_defined() ? Cycle.lift(self.toCyclerApi()) : Cycle.ZERO;
  }
  public inline function step(){
    return this == null ? Cycler.unit() : this;
  }
  public inline function is_defined(){
    return this != null;
  }
  public function toString(){
    return 'Cycle(${is_defined()})';
  }
}
class CycleLift{
  static public inline function lift(self:CyclerApi):Cycle return @:privateAccess Cycle.lift(self);

  static public function seq(self:Cycle,that:Cycle):Cycle{
    #if debug
      //__.log().trace('seq setup $self $that');
    #end
    return switch([self.is_defined(),that.is_defined()]){
      case [false,false]    : Cycle.unit();
      case [false,true]     : that;
      case [true,false]     : self;
      case [true,true]      : 
        final next = self.step(); 
        switch(next.state){
          case CYCLE_NEXT : new Cycle(Cycler.pure(next.value.map(seq.bind(_,that))));
          case CYCLE_STOP : that;
        }
    }
  }
  static public function par(self:Cycle,that:Cycle):Cycle{
    #if debug
    __.assert().exists(self);
    __.assert().exists(that);
    #end
    var l = self.step();
    var r = self.step();
  
    return switch([l.state,r.state]){
      case [CYCLE_STOP,CYCLE_STOP] : Cycler.unit();
      case [CYCLE_NEXT,CYCLE_STOP] : Cycler.pure(l.value);
      case [CYCLE_STOP,CYCLE_NEXT] : Cycler.pure(r.value);
      case [CYCLE_NEXT,CYCLE_NEXT] : Cycler.pure(l.value.merge(r.value,seq));
    }
  }
  static public function submit(self:Cycle,?pos:Pos){
    __.log().info('cycle/submit: $self $pos');
    var event : haxe.MainLoop.MainEvent = null;
        event = haxe.MainLoop.add(
          () -> {
            __.log().trace('tick: $self');
            if(self != null){
              try{
                var thiz = self;
                __.log().trace(thiz.toString());
                self = null;
                var step = thiz.step();
                __.log().trace(_ -> _.thunk(()  -> step.state));
                switch(step.state){
                  case CYCLE_STOP : 
                      event.stop();
                  case CYCLE_NEXT :
                    //__.log().trace('next');
                    step.value.handle(
                      x -> {
                        self = x;
                      }
                    );
                }
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
            final result = call.step();
            switch(result.state){
              case CYCLE_STOP : 
                cont = false;
                null;
              case CYCLE_NEXT :
                result.value.handle(
                  x -> self = x
                );
                null;
            }
          }
        }
      }
    }
    inner(self);
  }
}