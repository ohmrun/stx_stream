package stx.stream;

using stx.stream.Logging;

enum CYCLED{
  CYCLED;
}
enum abstract CycleState(UInt){
  var CYCLE_STOP   = 0;
  var CYCLE_NEXT   = 1;
  //var CYCLE_WAIT = 2;
}
interface CyclerApi{
  public var state(get,null)          : CycleState;
  public function get_state()         : CycleState;
  
  public var value(get,null)          : Null<Future<Cycle>>;
  public function get_value()         : Null<Future<Cycle>>;

  public function toString():String;
  public function toCyclerApi():CyclerApi;

  public final uuid : String;
}
abstract class CyclerCls implements CyclerApi{
  public final uuid : String;
  public function new(){
    this.uuid = __.uuid("xxxxx");
  }
  
  public var state(get,null)            : CycleState;
  abstract public function get_state()  : CycleState;

  public var value(get,null)            : Null<Future<Cycle>>;
  abstract public function get_value()  : Null<Future<Cycle>>;

  public inline function toString(){
    final type = __.definition(this).identifier();
    return '$type[$uuid]($state:$value)';
  } 
  public function toCyclerApi():CyclerApi{
    return this;
  }
}
class AnonCyclerCls extends CyclerCls{
  final method : Void -> Null<Future<Cycle>>;
  public function new(method:Void -> Null<Future<Cycle>>){
    super();
    this.method = Thunk.lift(method).cache().prj();
  }
  public function get_value(){
    return this.method();
  }
  public function get_state(){
    return this.get_value() == null ? CYCLE_STOP : CYCLE_NEXT;
  }
}
/**
  TODO remove state
**/
class UnitCyclerCls extends CyclerCls{
  public function new(){
    super();
  }
  public function get_value(){
    return null;
  }
  public function get_state(){
    return CYCLE_STOP;
  }
}
class PureCyclerCls extends CyclerCls{
  public function new(value){
    super();
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
@:forward(toCyclerApi,value) abstract Cycle(CyclerApi) from CyclerApi to CyclerApi{
  public function new(self:CyclerApi) {
    //__.assert().that().exists(self);
    this = self;
  }
  static private inline function lift(self:CyclerApi):Cycle{
    //__.assert().that().exists(self);
    return new Cycle(self);
  }
  static public var ZERO(get,null) : Cycle;
  static private inline function get_ZERO():Cycle{
    return ZERO == null ? ZERO = unit() : ZERO;
  }
  static public inline function unit():Cycle{
    return lift(Cycler.unit());
  }
  static public inline function anon(f:Void->Null<Future<Cycle>>):Cycle{
    return lift(new AnonCyclerCls(f));
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
    final type = __.definition(this).identifier();
    return '$type[${this.uuid}](${this.state:${this.value}})';
  }
}
class CycleLift{
  static public inline function lift(self:CyclerApi):Cycle return @:privateAccess Cycle.lift(self);

  static public function seq(self:Cycle,that:Cycle):Cycle{
    #if debug
      __.log().debug('seq setup $self $that');
      __.log().trace('${self.is_defined()} ${that.is_defined()}');
    #end
    return switch([self.is_defined(),that.is_defined()]){
      case [false,false]    : Cycle.unit();
      case [false,true]     : that;
      case [true,false]     : self;
      case [true,true]      : 
        final next = self.step(); 
        __.log().debug('${next.state}');
        switch(next.state){
          case CYCLE_NEXT : new Cycle(
            Cycler.pure(
              next.value
              .map(
                x -> {
                  __.log().trace('$x');
                  return x;
                }
              ).map(seq.bind(_,that))
            )
          );
          case CYCLE_STOP : 
            next.value;//Run the lazy getter in case it's an error inside
            that;
        }
    }
  }
  static public function par(self:Cycle,that:Cycle):Cycle{
    #if debug
    __.assert().that().exists(self);
    __.assert().that().exists(that);
    #end
    var l = self.step();
        l.value;
    var r = that.step();
        r.value;
    //trace('$l$r');
    return switch([l.state,r.state]){
      case [CYCLE_STOP,CYCLE_STOP] : Cycler.unit();
      case [CYCLE_NEXT,CYCLE_STOP] : Cycler.pure(l.value);
      case [CYCLE_STOP,CYCLE_NEXT] : Cycler.pure(r.value);
      case [CYCLE_NEXT,CYCLE_NEXT] : Cycler.pure(l.value.merge(r.value,par));
    }
  }
  static public function submit(self:Cycle,?pos:Pos){
    __.log().debug('cycle/submit: $self ${(pos:Position)}');
    stx.stream.scheduler.Haxe.apply(self,pos);
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
            __.log().blank('step $result');
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