package stx;

import tink.core.Callback;
import tink.core.Disposable;
import tink.core.Signal in TinkSignal;

using stx.stream.Logging;

typedef Timeout                                 = stx.stream.Timeout;
typedef Work                                    = stx.stream.Work;
typedef Bang                                    = stx.stream.Work.Bang;
typedef Cycle                                   = stx.stream.Cycle;
typedef CYCLED                                  = stx.stream.Cycle.CYCLED;
typedef CycleState                              = stx.stream.Cycle.CycleState;
typedef Cycler                                  = stx.stream.Cycle.Cycler;
typedef Window<T,E>                             = stx.stream.Window<T,E>;
typedef Buffer<T>                               = stx.stream.Buffer<T>;

typedef StreamDef<T,E>                          = Signal<Chunk<T,E>>;

@:using(stx.Stream.StreamLift)
@:forward(handle) abstract Stream<T,E>(StreamDef<T,E>) from StreamDef<T,E>{
  public function new(self) this = self;
  @:noUsing static public function lift<T,E>(self:StreamDef<T,E>):Stream<T,E> return new Stream(self);
  
  //static public function trigger<T,E>():
  static public function fromArray<T,E>(self:Array<T>):Stream<T,E>{
    return lift(Signal.fromArray(self.map(Val).snoc(End())));
  }
  static public function fromFuture<T,E>(self:Future<T>):Stream<T,E>{
    return fromThunkFuture(() -> self);
  }
  public function window(?buffer:Buffer<Chunk<T,E>>):Stream<T,E>{
    return lift(Window.make(this,buffer).toSignal());
  }
  static inline public function fromThunkFuture<T,E>(self:Void->Future<T>):Stream<T,E>{
    return lift(
      Signal.make(
        (cb) -> {
          return self().handle(
            x -> {
              cb(Val(x));
              cb(End());
            }
          );
        }
      )
    );
  }
  @:noUsing static public function pure<T,E>(self:T):Stream<T,E>{
    return lift(
      Signal.make(
        cb -> {
          cb(Val(self));
          cb(End());
          return () -> {};
        }
      )
    );
  }
  static public function effect<T,E>(self:Void->Void):Stream<T,E>{
    return lift(
      Signal.make(
        cb -> {
          self();
          cb(End());
          return () -> {};
        }
      )
    );
  }
  static public function unit<T,E>():Stream<T,E>{
    //__.log().blank("unit");
    return lift(
      Signal.make(
        (cb:Chunk<T,E>->Void) -> {
          cb(End());
          return () -> {};
        }  
      )
    );
  }
  @:noUsing static public function make<T,E>(f:(fire:Chunk<T,E>->Void)->CallbackLink, ?init:OwnedDisposable->Void):Stream<T,E>{
    return lift(new TinkSignal(f,init));
  }
  public function map<Ti>(fn:T->Ti):Stream<Ti,E>{
    return this.map(
      (chunk) -> chunk.map(fn)  
    );
  }
  public function prj():StreamDef<T,E> return this;
  private var self(get,never):Stream<T,E>;
  private function get_self():Stream<T,E> return lift(this);
}
class StreamLift{
  static function lift<T,E>(self:StreamDef<T,E>):Stream<T,E>{
    return Stream.lift(self);
  }
  static public function seq<T,E>(self:Stream<T,E>,that:Stream<T,E>):Stream<T,E>{
    var id        = __.uuid("xxxx");
    //__.log().blank('seq');
    var ended = false;
    return lift(Signal.make(
      (cb) -> {
        var cbII = null;
        //__.log().blank(_ -> _.pure(self));
        var cbI  = self.handle(
          (chunk) -> {
            //__.log().blank('stream:${id} log:lhs ');
            //__.assert().exists(chunk);
            chunk.fold(
              val -> cb(Val(val)),
              end -> __.option(end).fold(
                err -> cb(End(err)),
                ()  -> {
                  //__.log().blank('stream:${id} log:lhs:end()');
                  cbII = that.handle(
                      (chunk) -> {
                        chunk.fold(
                        (val) -> {
                          if(!ended){
                            cb(Val(val));
                          }else{
                            cb(End(__.fault().explain(_ -> _.e_end_called_twice())));
                          }
                        },
                        (end) -> {
                          //__.log().blank('stream:${id} rhs:end');
                          ended = true;
                          cb(End(end));
                        },
                        ()    -> {
                          //TODO should I forward this?
                        }
                      );
                    }
                  );
                }
              ),
              () -> {}
            );
          }
        );
        return () -> {
          for(link in __.option(cbI)){
            link.cancel();
          }
          for(link in __.option(cbII)){
            link.cancel();
          }
        }
      }
    ));
  }
  //TODO I'm not sure how to handle ordering in the substreams. Possibly for a subclass to handle with a LogicalClock.
  static public function flat_map<T,Ti,E>(self:Stream<T,E>,fn:T->Stream<Ti,E>){
    var cancelled = false;
    var streams   = [];
    var id        = Math.random();
    return lift(
      new TinkSignal(
        (cb) -> {
          //__.log().blank('$id $self');
          var callbackI   = null;
          final callback  = self.handle(
            (chunk) -> chunk.fold(
              val -> {
                if(!cancelled){
                  __.log().trace(_ -> _.thunk(() -> '$val'));
                  //__.log().blank("ADDED STREAM");
                  streams.push(fn(val));
                }
              },
              end -> __.option(end).fold(
                err -> {
                  //__.log().blank('CANCELLED $err');
                cancelled = true;
                  streams   = [];
                  cb(End(err));
                },
                () -> {
                  //__.log().blank('stream:${id} SEQ ${streams.length} ');
                  callbackI = streams.lfold1(seq).defv(Stream.unit()).handle(
                    chunk -> {
                      //__.log().blank('$chunk');
                      cb(chunk);
                    }
                  );
                }
              ),
              () -> {
                
              }
            )
          );
          return () -> {
            for(link in __.option(callback)){
              link.cancel();
            }
            for(link in __.option(callbackI)){
              link.cancel();
            }  
          };
        }
      )
    );
  }
  static public function next<T,E>(self:Stream<T,E>):Future<Chunk<T,E>>{
    return self.prj().nextTime();
  }
  static public function errata<T,E,EE>(self:Stream<T,E>,fn:Refuse<E>->Refuse<EE>):Stream<T,EE>{
    return lift(self.prj().map(
      chk -> chk.errata(fn)
    ));
  }
  static public function errate<T,E,EE>(self:Stream<T,E>,fn:E->EE):Stream<T,EE>{
    return lift(self.prj().map(
      chk -> chk.errate(fn)
    ));
  }
}