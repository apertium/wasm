After building CG-3, run a HTTP daemon in its `build/src` folder and load `vislcg3.html` and run the code below in the console.

```javascript
{
	let cglb = Module.cwrap('cg3_grammar_load_buffer', 'number', ['string', 'number']);
	let cac = Module.cwrap('cg3_applicator_create', 'number', ['number']);
	let crgotf = Module.cwrap('cg3_run_grammar_on_text_fns', null, ['number', 'string', 'string']);

	let g = cglb('DELIMITERS = "<.>"; SELECT (tag) ;', 'DELIMITERS = "<.>"; SELECT (tag) ;'.length);
	let a = cac(g);

	FS.writeFile('/tmp/input.txt', '"<woærd>"\n\t"woørd" tag\n\t"woård" nottag\n');
	crgotf(a, '/tmp/input.txt', '/tmp/output.txt');

	console.log(FS.readFile('/tmp/output.txt', {'encoding': 'utf8'}));
}
```

Yields output:
```
"<woærd>"
	"woørd" tag
```
