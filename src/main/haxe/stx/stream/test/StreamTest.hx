package stx.stream.test;

class StreamTest extends Clazz{
	public function test(){
		final a = Stream.fromFuture(Future.delay(300,() -> 1));
		final b = (i:Int) -> Stream.fromArray([1,2,3,4]);
		final c = a.flat_map(b);
		c.handle(
			(x) -> {
				__.log().debug(_ -> _.pure(x));
			}
		);
	}
	public function test1(){
		final a = Stream.fromFuture(Future.delay(300,() -> 1));
		final b = Stream.fromArray([2,3,4,5]);
		final c = a.seq(b);
					c.handle(
						(x) -> {
							__.log().debug(_ -> _.pure(x));
						}
					);
	}
	//public function test2
}