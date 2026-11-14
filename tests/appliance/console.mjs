import fs from 'node:fs/promises';
import net from 'node:net';
import { setTimeout as delay } from 'node:timers/promises';

const [directory, phase] = process.argv.slice(2);
const log = directory + '/artifacts/' + (['install', 'sets', 'package'].includes(phase) ? phase : 'package') + '.log';
const socket = await new Promise((resolve, reject) => {
  const connection = net.connect(directory + '/console.sock', () => resolve(connection));
  connection.once('error', reject);
});
socket.on('data', () => {});
let offset = 0;

async function waitFor(marker, seconds = 240) {
  for (let attempt = 0; attempt < seconds * 4; attempt++) {
    const bytes = await fs.readFile(log);
    const index = bytes.indexOf(marker, offset);
    if (index !== -1) {
      offset = index + Buffer.byteLength(marker);
      return;
    }
    await delay(250);
  }
  throw new Error(`Missing console marker: ${marker}`);
}

async function send(input) {
  socket.write(input);
  await delay(750);
}

async function shell(command) {
  // Build the result token in the guest so the echoed command cannot match it.
  await send(command + '; set result=$status; echo "BROWSER_"RESULT="$result"\r');
  await waitFor('BROWSER_RESULT=', 480);
  await waitFor('\r\n', 10);
  const line = (await fs.readFile(log)).subarray(0, offset).toString().match(/BROWSER_RESULT=(\d+)\r\n$/);
  if (line?.[1] !== '0') throw new Error(`Guest command failed: ${command}`);
}

try {
  if (phase === 'install') {
    await waitFor('login:');
    await send('installer\r');
    await waitFor('Password:');
    await send('opnsense\r');
    await waitFor('Choose one of the following tasks');
    await send('\x1bOB');
    await send('\r');
    await waitFor('Please select a disk');
    await send('\r');
    await waitFor('Last Chance!');
    await send('\r');
    await waitFor('Complete Install', 480);
    await send('\x1bOB');
    await send('\r');
    await waitFor('Halt now');
    await send('\x1bOB');
    await send('\r');
    await waitFor('Powering system off');
  } else if (phase === 'sets' || phase === 'package') {
    await waitFor('login:');
    await send('root\r');
    await waitFor('Password:');
    await send('opnsense\r');
    await waitFor('Shell');
    await send('8\r');
    await waitFor('# ');
    await shell('mkdir -p /tmp/browser-inputs && mount -t cd9660 -o ro /dev/cd0 /tmp/browser-inputs && sh /tmp/browser-inputs/prepare-guest.sh ' + phase);
    if (phase === 'sets') {
      await send('shutdown -p now\r');
      await waitFor('Powering system off');
    }
  } else {
    const commands = {
      dark: 'php /tmp/browser-build/plugin/tests/native/browser-theme.php opnsense-dark',
      reject: 'sh /tmp/browser-build/plugin/tests/native/browser-push-reject.sh reject',
      accept: 'sh /tmp/browser-build/plugin/tests/native/browser-push-reject.sh accept',
      growth: 'sh /tmp/browser-build/plugin/tests/native/browser-growth.sh',
    };
    if (!Object.hasOwn(commands, phase)) throw new Error('Unknown browser fixture phase');
    // Further commands use the live package-phase serial log.
    offset = (await fs.stat(directory + '/artifacts/package.log')).size;
    await shell(commands[phase]);
  }
} finally {
  socket.end();
}
