#!/usr/bin/env node
import {openSync, fstatSync, readSync, closeSync, existsSync} from 'node:fs';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {dirname, resolve, join} from 'node:path';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)), '..');
const args=process.argv.slice(2);
function fail(message) { console.error('ptp-audit: '+message); process.exit(2); }
if (args.length===1 && args[0]==='--version') { console.log('ptp-audit 0.3.0'); process.exit(0); }
if (args.length===1 && args[0]==='--help') {
  console.log('Usage: ptp-audit check <case.json> [--json]\n       ptp-audit commission <campaign.json> [--json]\nExit: 0 supported checks pass, 1 violation, 2 usage/I/O/build, 3 insufficient evidence, 4 unsupported.\nTiming-limit assessments have separate within_limit/outside_limit/indeterminate verdicts; exit 0 alone is not operational acceptance.\nRequires Node.js >=22 and the MoonBit toolchain. Builds the local MoonBit JS CLI before checking.'); process.exit(0);
}
if (!['check','commission'].includes(args[0]) || args.length<2 || args.length>3 || (args.length===3 && args[2]!=='--json')) fail('use --help for usage');
let fd;
try {
  fd=openSync(resolve(args[1]),'r');
  const stat=fstatSync(fd);
  if (!stat.isFile() || stat.size>1048576) throw new Error('expected a regular file of at most 1 MiB');
  const buffer=Buffer.alloc(1048577);
  let count=0;
  while(count<buffer.length) { const n=readSync(fd,buffer,count,buffer.length-count,null); if(!n) break; count+=n; }
  if(count>1048576) throw new Error('input grew beyond 1 MiB');
  globalThis.__ptpAuditInput=new TextDecoder('utf-8',{fatal:true}).decode(buffer.subarray(0,count));
} catch(error) { fail(error.message); } finally { if(fd!==undefined) closeSync(fd); }
globalThis.__ptpAuditJson=args.includes('--json');
globalThis.__ptpAuditCommand=args[0];
const installed=process.env.HOME ? join(process.env.HOME,'.moon','bin','moon') : '';
const compiler=process.env.PTP_AUDIT_MOON || (existsSync(installed)?installed:'moon');
const build=spawnSync(compiler,['build','--target','js','cmd/ptp-audit'],{cwd:root,encoding:'utf8',maxBuffer:4*1024*1024});
if(build.error || build.status!==0) fail('MoonBit build failed: '+(build.error?.message || build.stderr || build.stdout));
try { await import(pathToFileURL(join(root,'_build/js/debug/build/cmd/ptp-audit/ptp-audit.js')).href); }
catch(error) { fail('cannot run MoonBit CLI: '+error.message); }
