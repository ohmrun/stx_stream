package stx.stream;

typedef WorkDef = Null<Cycle>;

@:using(stx.stream.Work.WorkLift)
@:forward(toCyclerApi) abstract Work(WorkDef) from WorkDef to WorkDef{
  @:noUsing static inline public function unit():Work{
    return lift(null);
  }
  static public inline function wait():Bang{
    return new Bang();
  }
  public inline function new(self) this = self;
  static public inline function lift(self:WorkDef):Work return new Work(self);

  public inline function prj():WorkDef return this;
  private var self(get,never):Work;
  private inline function get_self():Work return lift(this);

  static public inline function fromCycle(self:Cycle):Work{
    return Work.lift(self);
  }
  @:from static public inline function fromFutureWork(ft:Future<Work>):Work{
    return lift(
      new Cycle(Cycler.pure(ft.flatMap(
        (bang) -> bang == null ? Cycle.ZERO : bang
      )))
    );
  } 
  @:to public function toCycle():Cycle{
    return Cycle.fromWork(this);
  }
  public function is_defined():Bool{
    return this != null;
  }
}
@:forward(handle) abstract Bang(FutureTrigger<Cycle>){
  public function new(){
    this = Future.trigger();
  }
  public function fill(block:Cycle):Void{
    this.trigger(block);
  }
  public function done():Void{
    this.trigger(Cycle.ZERO);
  }
  // public function pass(bang:Work){
    
  // }
  @:to public function toWork():Work{
    return Work.lift(
      this == null ? null : new Cycle(Cycler.pure(this.asFuture()))
    );
  }
  static public function unit(){
    return new Bang();
  }
}
class WorkLift{
  @:noUsing static inline public function lift(self:WorkDef):Work return Work.lift(self);

  static public function seq(self:Work,that:Work):Work{
    __.log().trace('work seq setup $self $that');
    return lift(
      switch([self,that]){
        case [null,null] : null;
        case [x,null]    : x;
        case [null,y]    : y;
        case [x,y]       : (x:Cycle).seq((y:Cycle));
      }
    );
  }
  static public function par(self:Work,that:Work):Work{
    //__.log().blank('work par setup');
    return lift(
      switch([self,that]){
        case [null,null] : null;
        case [x,null]    : x;
        case [null,y]    : y;
        case [x,y]       : (x:Cycle).par((y:Cycle));
      }
    );
  }
}