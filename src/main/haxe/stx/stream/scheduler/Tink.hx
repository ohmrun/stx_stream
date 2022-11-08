package stx.stream.scheduler;

import tink.runloop.Task;
import tink.RunLoop;

class Tink{
  static var bindings = 0;
  static public function apply(self:Cycle,?pos:Pos){
    __.log().trace('Tink.apply ${(pos:Position)} $self');
    final worker    = RunLoop.current;
    // self.toCyclerApi().value.handle(
    //   x -> {
    //     trace(x);
    //   }
    // );
    switch(self.toCyclerApi().state){
      case CYCLE_NEXT :
        trace('work');
        worker.work(
          Task.ofFunction(function task(){
            trace('task');
            final api = self.toCyclerApi();
            trace('task ${api.state} ${api.value}');
            switch(api.state){
              case CYCLE_NEXT :
                switch(api.value){
                  case null : throw 'error';
                  case x    : 
                    trace(bindings);
                    function next(x){
                      __.log().trace('handled ${(pos:Position)}');
                        self = x;
                        worker.work(task);
                    }
                    function unbind(x){
                      __.log().trace('unbound ${(pos:Position)}');
                      bindings = bindings-1;
                      next(x);
                    }
                    if(bindings > 0){
                      __.log().trace('handling ${(pos:Position)}');
                      x.handle(next);  
                    }else{
                      __.log().trace('binding ${(pos:Position)}');
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
    // function step(){
    //   trace(task.state);
    //   switch(task.state){
    //     case Busy : 
    //       switch(self.toCyclerApi().value){
    //         case null  : throw 'empty cycle';
    //         case x     : 
    //           x.handle(
    //             worker.bind((_) -> {
    //               trace('bound');
    //               step();
    //             })
    //           );
    //       }
    //     case Pending  : 
    //       worker.work(task);
    //     default       : 
    //   }
    // }
    // step();
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
    trace('perform ${this.state} ${cycle.toCyclerApi().state}');
    switch(this.state){
      case Busy    : 
      case Pending :
        trace(cycle.toCyclerApi().state);
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
                        trace('next: ${this.state}');
    
                      }
                    ); 
                }
            }
        }
        default : 
    }
  } 
}