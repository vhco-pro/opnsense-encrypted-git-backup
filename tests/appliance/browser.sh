#!/usr/bin/env bash
set -euo pipefail
directory=$(realpath "$1")
export FIXTURE_APPLIANCE_URL=https://127.0.0.1:38443
export FIXTURE_ADMIN=root FIXTURE_ADMIN_PASSWORD=opnsense
export FIXTURE_READER_PASSWORD=synthetic-browser-only
pid=
cleanup() {
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT
if [[ ${BROWSER_APPLIANCE_STAGED:-} != 1 ]]; then
    bash tests/appliance/stage.sh "$directory"
fi
qemu-img create -f qcow2 "$directory/appliance.qcow2" 18G
accelerator=tcg
if [[ -w /dev/kvm ]]; then accelerator=kvm; fi
boot() {
    local phase=$1
    shift
    rm -f "$directory/console.sock"
    : > "$directory/artifacts/$phase.log"
    qemu-system-x86_64 -nodefaults -display none -monitor none -accel "$accelerator" \
        -smp 2 -m 3072 \
        -drive "file=$directory/appliance.qcow2,if=none,id=target,format=qcow2" \
        -device "virtio-blk-pci,drive=target,bootindex=2" \
        -serial "unix:$directory/console.sock,server=on,wait=on,logfile=$directory/artifacts/$phase.log" \
        "$@" >"$directory/artifacts/$phase-qemu.log" 2>&1 &
    pid=$!
    for attempt in {1..50}; do
        [[ -S "$directory/console.sock" ]] && break
        kill -0 "$pid"
        sleep 0.2
    done
    node tests/appliance/console.mjs "$directory" "$phase"
}
boot install -drive "file=$directory/installer.img,if=none,id=installer,format=raw,snapshot=on" \
    -device "virtio-blk-pci,drive=installer,bootindex=1" \
    -device e1000,netdev=fixture -netdev user,id=fixture,restrict=on
wait "$pid"
pid=
boot sets -cdrom "$directory/inputs.iso" -boot order=c \
    -device e1000,netdev=fixture -netdev user,id=fixture,restrict=on
wait "$pid"
pid=
boot package -cdrom "$directory/inputs.iso" -boot order=c \
    -device e1000,netdev=fixture -netdev user,id=fixture,restrict=on,hostfwd=tcp:127.0.0.1:38443-10.0.2.15:443
FIXTURE_EXPECT_THEME=opnsense bun x playwright test --output "$directory/artifacts/light"
node tests/appliance/console.mjs "$directory" dark
FIXTURE_EXPECT_THEME=opnsense-dark bun x playwright test --grep 'fits narrow' --output "$directory/artifacts/dark"
node tests/appliance/console.mjs "$directory" reject
FIXTURE_PUSH_REJECTED=1 bun x playwright test --grep 'rejected delivery' --output "$directory/artifacts/rejected"
node tests/appliance/console.mjs "$directory" accept
openssl s_client -connect 127.0.0.1:38443 </dev/null 2>/dev/null | openssl x509 -out "$directory/artifacts/r45-fixture-cert.pem"
timeout 90s node tests/appliance/chromium-zoom.mjs "$directory/artifacts" | tee "$directory/artifacts/chromium-zoom.log"
timeout 90s node tests/appliance/firefox-real-zoom.mjs "$directory/artifacts" | tee "$directory/artifacts/firefox-zoom.log"
node tests/appliance/console.mjs "$directory" growth
