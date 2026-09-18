// Runs a WASI command module under Node, with the whole file system visible.
//
// For SeedCore's test suite built for WebAssembly:
//   node tools/wasm/run-wasi.mjs <scratch>/debug/SeedCorePackageTests.xctest
// Exits with the module's own status, so a failing test fails the step.
import { readFile } from 'node:fs/promises';
import { WASI } from 'node:wasi';
import { argv, env, exit } from 'node:process';

const [file, ...args] = argv.slice(2);
const wasi = new WASI({ version: 'preview1', args: [file, ...args], env, preopens: { '/': '/' }, returnOnExit: true });
const module = await WebAssembly.compile(await readFile(file));
const instance = await WebAssembly.instantiate(module, wasi.getImportObject());
exit(wasi.start(instance));
