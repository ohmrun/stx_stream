package stx.stream.buffer;

typedef DrainDef<T,E> = Buffer<Chunk<T,E>>;

abstract Drain<T,E>(DrainDef<T,E>) from DrainDef<T,E> to DrainDef<T,E>{
  public function new(self) this = self;
  static public function lift<T,E>(self:DrainDef<T,E>):Drain<T,E> return new Drain(self);

   
  public function prj():DrainDef<T,E> return this;
  private var self(get,never):Drain<T,E>;
  private function get_self():Drain<T,E> return lift(this);
}