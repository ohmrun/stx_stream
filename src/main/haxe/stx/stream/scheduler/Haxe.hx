package stx.stream.scheduler;

import haxe.MainLoop;

class Haxe{
  static public function apply(self:Cycle,?pos:Pos){
    __.log().trace('Haxe.apply');
    final ignition  = Future.lazy(Noise);
    var event       = null;
        event       = MainLoop.add(
          (function start(cycle:Ref<Cycle>){
            __.log().trace('start ${cycle.value}');
            switch(cycle.value?.value){
              case null :
                __.log().trace('nothing remains');
                event.stop();
              case x    : 
                var local : Null<Cycle> = null;
                __.log().trace('initialise local');
                function next(){
                  x.handle(
                    (x) -> {
                      __.log().trace('start');
                      start(x);
                    }
                  );
                }
                var cancelled = false;
                var cbh = x.handle(
                  (c) -> {
                    if(!cancelled){
                      __.log().trace('set local as $c');
                      local = c;
                    }else{
                      __.log().trace('already cancelled');
                    }
                  }
                );
                __.log().trace('local is set synchronousely as $local');
                if(local == null){
                  cbh.cancel();
                  cancelled = true;
                  __.log().trace('STOP');
                  event.stop();
                  event = MainLoop.add(next);
                }else{
                  __.log().trace('switch out cycle value ${haxe.MainLoop.hasEvents()}');
                  cycle.value = local;
                }
            };
          }).bind(self)
        );
  }
}