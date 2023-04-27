package stx.stream.scheduler;

import haxe.MainLoop;

class Haxe{
  static public function apply(self:Cycle,?pos:Pos){
    final ignition  = Future.lazy(Noise);
    var event       = null;
        event       = MainLoop.add(
          (function start(cycle:Ref<Cycle>){
            switch(cycle.value){
              case null :
              case x    : 
                switch(x.toCyclerApi().value){
                  case null : 
                  case f    :
                    switch(x.toCyclerApi().state){
                      case CYCLE_STOP : 
                      case CYCLE_NEXT : 
                        var local : Null<Cycle> = null;
                        function next(){
                          f.handle(
                            (x) -> {
                              start(x);
                            }
                          );
                        }
                        f.handle(
                          (c) -> {
                            local = c;
                          }
                        );
                        if(local == null){
                          event.stop();
                          event = MainLoop.add(next);
                        }else{
                          cycle.value = local;
                        }
                    }
                }
            };
          }).bind(self)
        );
  }
}