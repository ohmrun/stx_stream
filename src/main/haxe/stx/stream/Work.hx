package stx.stream;

typedef WorkDef = Option<Cycle>;

@:using(stx.stream.Work.WorkLift)
@:callable abstract Work(WorkDef) from WorkDef to WorkDef{
  @:noUsing static public function unit():Work{
    return lift(None);
  }
  static public function wait():Bang{
    return new Bang();
  }
  public function new(self) this = self;
  static public function lift(self:WorkDef):Work return new Work(self);

  public function prj():WorkDef return this;
  private var self(get,never):Work;
  private function get_self():Work return lift(this);

  static public inline function fromCycle(self:Cycle):Work{
    return __.option(self);
  }
  @:from static public function fromFutureWork(ft:Future<Work>):Work{
    return lift(Some(
      () -> __.couple(CYCLE_NEXT,ft.flatMap(
        (bang) -> bang.prj().fold(
          ok -> ok,
          () -> Cycle.ZERO
        )
      )
    )));
  } 
  @:to public function toCycle():Cycle{
    return Cycle.fromWork(this);
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
    return Work.lift(Some(() -> __.couple(CYCLE_NEXT,this.asFuture())));
  }
}
class WorkLift{
  static public function lift(self:WorkDef):Work return Work.lift(self);

  static public function seq(self:Work,that:Work):Work{
    //__.log().trace('work seq setup $self $that');
    return lift(
      self.prj().zip(that.prj()).map(
        tp -> tp.decouple(
          (lhs:Cycle,rhs:Cycle) -> {
            //__.log().trace('$lhs $rhs');
            return lhs.seq(rhs);
          }
        )
      ).or(() -> self.prj()) 
       .or(() -> that.prj())
    );
  }
  static public function par(self:Work,that:Work):Work{
    //__.log().blank('work par setup');
    return lift(
      Work.lift(
        self.prj().zip(that.prj()).map(
          (tp:Couple<Cycle,Cycle>) -> tp.decouple(
            (lhs:Cycle,rhs:Cycle) -> {
              return lhs.par(rhs);
            }
          )
        ).or(() -> self.prj()) 
         .or(() -> that.prj())
       )
    );
  }
}