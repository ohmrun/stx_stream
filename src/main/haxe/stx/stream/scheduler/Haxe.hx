package stx.stream.scheduler;

import haxe.MainLoop;

class Haxe{
  static public function apply(self:Cycle,?pos:Pos){
    __.log().trace('Haxe.apply');
    final ignition                = Future.irreversible((cb) -> cb(Nada));
    final cycle : Ref<Cycle>      = self; 
    var event       = null;
        event       = MainLoop.add(
          (function start(){
            if(event!=null){
              event.stop();
            }
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
                      __.log().trace('start: $x');
                      cycle.value = x;
                      start();
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
                  var t = new haxe.Timer(0);
                      t.run = t.stop;
                }else{
                  __.log().trace('switch out cycle value ${haxe.MainLoop.hasEvents()}');
                  cycle.value = local;
                  __.log().trace('cycle.value = $local');
                  event       = MainLoop.add(start);
                }
            };
          })
        );
        var t     = new haxe.Timer(0);//https://github.com/HaxeFoundation/haxe/issues/11202
            t.run = t.stop;
  }
}