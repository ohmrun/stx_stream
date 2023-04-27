# stx_stream

This is a possibly inifinite functional Stream with windowing based on coroutines running on an event loop.

Usage.

```haxe
  //Based on `tink.core.Signal<stx.nano.Chunk<T,E>>`
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
### Windowing

The Windowing system `stream.window` is fully asyncrhonous, and by default keeps a full history of the values in memory. Overriding what the window returns and how is managed by a `stx.coroutine.Tunnel` which allows arbitrarily complex behaviours based on the input, and is integrated with `stx.Fail`.

### Execution

Execution is started using `cycle.submit()` or `cycle.crunch()`. The latter attempts to complete execution in the current event loop frame.

### Logging (stx.log)
To read the logs, whitelist `stx/stream`, set level to `TRACE` 

```haxe
  function log_init(){
    __.log().global.includes.push('stx/stream');
    __.log().global.level = TRACE;
  }
```