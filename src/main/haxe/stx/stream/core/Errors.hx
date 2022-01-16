package stx.stream.core;

class Errors{
  static public function e_end_called_twice(digests:Digests){
    return new EEndCalledTwice();
  }
}
class EEndCalledTwice extends Digest{
  public function new(){
    super("01FRQ80PZA3A57AZPXPQA7Z8YT","End called twice");
  }
}
