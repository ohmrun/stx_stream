using stx.Nano;
using stx.Log;
using stx.Pico;
using tink.CoreApi;
using stx.stream.Logging;
using stx.Stream;
using stx.Test;

import stx.stream.Test;

class Main {
	static function main() {
		var includes = switch(2){
			case 0 		: ['stx/stream','stx/stream/test','stx/coroutine','eu/ohmrun/fletcher','haxe/overrides'];
			case 1 		: ['haxe/overrides'];
			case 2 		: ['stx/stream','haxe/overrides'];
			default 	: [];
		}
		var logger 					= stx.Logger.ZERO;
				logger.level	 	= TRACE;

		for(include in includes){
			logger.includes.push(include);
		}
				

		stx.stream.Test.main();

	}
}