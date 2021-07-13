# stx_stream

This is a possibly inifinite functional Stream with windowing based on coroutines running on an event loop (haxe.MainLoop)

Usage.

```haxe
  //Based on `tink.core.Signal<Chunk<T,E>>`
  class Main{
    static public function main(){
      final stream = Stream.make(
        (cb) -> {
          cb(Val(1));
          cb(End)
        }
      );
      final other     = Stream.fromArray([2,3,4,5]);
      final complete  = stream.seq(other)//[1,2,3,4,5]
    }
  }
```
`Stream` is a monad, with `map` and `flat_map` defined.

`stx.stream.Cycle` is `Thunk<Future<Cycle>>`, a recursive type.

The way `Cycle` reports that it is finished is via throwing a special constant `CYCLED`

`stx.stream.Work` is an `Option<Future<Cycle>>` (which might change to `Option<Cycle>`), but allows cases where the work is done to be factored out before the scheduler invocation `None + None = None`

The Windowing system `stream.window` is fully asyncrhonous, and by default keeps a full history of the values in memory. Overriding what the window returns and how is managed by a `stx.coroutine.Tunnel` which allows arbitrarily complex behaviours based on the input, and is integrated with `stx.Err`.