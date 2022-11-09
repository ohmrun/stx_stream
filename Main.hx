using stx.Nano;
using stx.Log;
using stx.Pico;
using tink.CoreApi;
using stx.stream.Logging;
using stx.Stream;
import stx.stream.Test;

class Main {
	static function main() {
		trace('main');
		#if threaded
		trace('threaded');
		#end
		var includes = switch(2){
			case 0 		: ['stx/stream','stx/stream/test','stx/coroutine','eu/ohmrun/fletcher','haxe/overrides'];
			case 1 		: ['haxe/overrides'];
			case 2 		: ['stx/stream','haxe/overrides'];
			default 	: [];
		}
		var logger 					= __.log().global;
				logger.level	 	= TRACE;

		stx.stream.Delay.comply(
			() -> {
				trace('goodbye');
			},
			3000
		);
		trace('hello');
		// for(include in includes){
		// 	logger.includes.push(include);
		// }
		// #if target.threaded
		// 	while(true){
		// 		final thread_count = stx.stream.delay.term.Threaded.pool.threadsCount;
		// 		if(thread_count == 0){
		// 			break;
		// 		}else{
		// 			Sys.sleep(0.2);
		// 		}
		// 	}
		// #end
	}
}