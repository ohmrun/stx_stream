package stx.stream.scheduler;

#if tink_runloop
import tink.runloop.Task;
import tink.RunLoop;

#end
class Tink{
  #if tink_runloop
  static var bindings = 0;
  static public function apply(self:Cycle,?pos:Pos){
    __.log().trace("!!!!!!!!!!!!!!!!!!!!!!TINK.APPLY!!!!!!!!!!!!!!!!!!!!!!!!");
    __.log().trace('Tink.apply ${(pos:Position)} $self');
    final worker    = RunLoop.current;
    // self.toCyclerApi().value.handle(
    //   x -> {
    //     trace(x);
    //   }
    // );
    //final latch = worker.bind((cb) -> cb(Nada));
    switch(self.toCyclerApi().state){
      case CYCLE_NEXT :
        __.log().trace('work');
        worker.work(
          Task.ofFunction(function task(){
            //latch.invoke((x) -> {});
            __.log().trace('working here');
            __.log().trace('task: $self');
            if(self == null) {
              return;
            }
            final api = self.toCyclerApi();
            __.log().trace('task ${api.state} ${api.value}');
            switch(api.state){
              case CYCLE_NEXT :
                switch(api.value){
                  case null : throw 'error';
                  case x    : 
                    __.log().trace('x $x bindings $bindings');
                    function next(x:Cycle){
                      __.log().trace('handled ${(pos:Position)} for $task');
                        self = x;
                        worker.work(task);
                    }
                    function unbind(x:Cycle){
                      __.log().trace('unbound ${(pos:Position)}');
                      bindings = bindings-1;
                      next(x);
                    }
                    if(bindings > 0){
                      __.log().trace('handling $x at ${(pos:Position)}');
                      x.handle(next);  
                    }else{
                      __.log().trace('binding $x at ${(pos:Position)}');
                      bindings = bindings+1;
                      x.handle(worker.bind(unbind));
                    }
                }
              case CYCLE_STOP:
            }
          })
        );
      default : 
    }
  }
}
private class CycleTask implements TaskObject{
  private var actual_state  : TaskState;
  public var cycle          : Cycle;
  public function new(cycle){
    this.cycle        = cycle;
    this.actual_state = Pending;
  }
  public var recurring(get, never):Bool;
  public function get_recurring(){
    return true;
  }
  public var state(get, never):TaskState;
  public function get_state(){
    return this.actual_state;
  }  
  public function cancel():Void{
    this.actual_state = Canceled;
  }
  public function perform():Void{
    __.log().trace('perform ${this.state} ${cycle.toCyclerApi().state}');
    switch(this.state){
      case Busy    : 
      case Pending :
        __.log().trace('${cycle.toCyclerApi().state}');
        switch(cycle.toCyclerApi().state){
          case CYCLE_STOP : 
            this.actual_state = Performed;
          case CYCLE_NEXT :
            switch(cycle.toCyclerApi().value){
              case null :
                throw 'empty value on CYCLE_NEXT';
              case x    :  
                switch(this.state){
                  case Canceled | Performed  : 
                  default                     :
                    this.actual_state = Busy;
                    x.handle(
                      (next) -> {
                        this.cycle        = next;
                        this.actual_state = switch(next.toCyclerApi().state){
                          case CYCLE_NEXT : Pending;
                          default         : Performed;
                        }
                        __.log().trace('next: ${this.state}');
                      }
                    ); 
                }
            }
        }
        default : 
    }
  } 
  #end
}