package stx.stream;

typedef WorkDef = Option<Future<Cycle>>;

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

  @:from static public function fromFutureWork(ft:Future<Work>):Work{
    return lift(Some(
      ft.flatMap(
        (bang) -> bang.prj().fold(
          ok -> ok,
          () -> Future.irreversible((cb) -> cb(Cycle.ZERO))
        )
      )
    ));
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
    return Work.lift(Some((this.asFuture())));
  }
}
class WorkLift{
  static public function lift(self:WorkDef):Work return Work.lift(self);

  static public function seq(self:Work,that:Work):Work{
    __.log().trace('work seq setup $self $that');
    return lift(
      self.prj().zip(that.prj()).map(
        tp -> tp.decouple(
          (lhs,rhs) -> {
            __.log().trace('$lhs $rhs');
            return Future.inSequence([lhs,rhs]).map(
              arr -> Cycle.lift(
                () -> {
                  __.log().trace('l:${arr[0]} and r:${arr[1]}');
                  return __.option(arr[0]).defv(Cycle.ZERO).seq(__.option(arr[1]).defv(Cycle.ZERO));
                }
              )
            );
          }
        )
      ).or(() -> self.prj()) 
       .or(() -> that.prj())
    );
  }
  static public function par(self:Work,that:Work):Work{
    __.log().trace('work par setup');
    return lift(
      self.prj().zip(that.prj()).map(
        tp -> tp.decouple(
          (lhs,rhs) -> {
            return Future.inParallel([lhs,rhs]).map(
              arr -> Cycle.lift(
                () -> __.option(arr[0]).defv(Cycle.ZERO).seq(__.option(arr[1]).defv(Cycle.ZERO))
              )
            );
          }
        )
      ).or(() -> self.prj()) 
       .or(() -> that.prj())
    );
  }
}