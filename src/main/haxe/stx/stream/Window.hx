package stx.stream;

abstract Window<T,E>(WindowCls<T,E>) from WindowCls<T,E>{
  public function new(self) this = self;
  @:noUsing static public function lift<T,E>(self:WindowCls<T,E>):Window<T,E> return new Window(self);
  @:noUsing static public function make<T,E>(delegate:Signal<Chunk<T,E>>,?buffer:Buffer<Chunk<T,E>>){
    return lift(new WindowCls(delegate,buffer));
  }
  @:to public function toSignal():Signal<Chunk<T,E>>{
    return this.toSignal();
  }
  public function prj():WindowCls<T,E> return this;
  private var self(get,never):Window<T,E>;
  private function get_self():Window<T,E> return lift(this);
}
class WindowCls<T,E>{
  private var buffer      : Buffer<Chunk<T,E>>;
  private final delegate  : Signal<Chunk<T,E>>;

  public function new(delegate:Signal<Chunk<T,E>>,?buffer:Buffer<Chunk<T,E>>){
    this.delegate = delegate;
    this.buffer   = __.option(buffer).defv(
      Buffer.lift(__.tran(
        function rec(x:Chunk<T,E>){
          __.log().debug('emit');
          return Emit(x,__.tran(rec));
        }  
      ))
    );
    __.log().trace(_ -> _.pure(this.buffer));
    this.delegate.handle(
      x -> {
        var next = this.buffer;
        __.log().trace('$next');
        this.buffer = next;
      }
    );
  }
  public function listen(handler:Callback<Chunk<T,E>>):CallbackLink{
    var uptake    = [];//between now and when the buffer has finished.
    var canceller = null;
    var uptaker = function(x){
      uptake.push(x);
    }
        canceller = this.delegate.handle(uptaker);  
    var partial = buffer;//snapshot of data now
  
    function transfer(){
      uptaker = (_) -> {};
        for(t in uptake){
          handler.invoke(t);//hope this is short? could equally add to to partial
        }
        if(canceller!=null){
          canceller.cancel();
        }
        delegate.handle(handler);
    }
    
      partial.source(() -> Future.irreversible((cb) -> cb(Right(Stop))))
             .emiter(_ -> End())
             .secure(Secure.handler(handler))
             .run()
             .handle(
                cause -> switch(cause){
                  case Some(Exit(e))  :
                    __.log().error(_ -> _.pure(e)); 
                    throw(e);
                  default             : transfer();
                }
             );
    return () -> {};
  }
  public function toSignal(){
    return new tink.core.Signal(this.listen);
  }
}