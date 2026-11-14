# Fold the approved checkpoint and every submission that could have advertised
# a catalogue. A closure never removes an advertised path.
def merge_packages($next):
  reduce ($next | to_entries[]) as $entry (.;
    if has($entry.key) and .[$entry.key] != $entry.value
    then error("conflicting advertised package digest")
    else .[$entry.key] = $entry.value end);
def packages:
  type == "object" and all(to_entries[];
    (.key | test("^([A-Za-z0-9_-]+/)*os-encrypted-git-backup-[A-Za-z0-9._-]+[.]pkg$"))
    and (.value | type == "string" and test("^[a-f0-9]{64}$")));
[.[] | select(.payload.phase == "history-checkpoint")] as $anchors |
[.[] | select(.payload.phase == "submission-started")] as $started |
if ($anchors | length) > 1 or ($started | length) > 1 then error("conflicting history journal")
elif ($checkpoint | packages | not) then error("invalid retained checkpoint")
elif ($anchors | length) == 1 and ($anchors[0].payload.digest != $digest
    or $anchors[0].payload.packages != $checkpoint) then error("retained history checkpoint changed")
else
  reduce $started[] as $entry ($checkpoint;
    if $entry.payload.history != $digest or ($entry.payload.packages | packages | not)
       or (merge_packages($entry.payload.packages) != $entry.payload.packages)
    then error("submission history does not extend its retained checkpoint")
    else $entry.payload.packages end)
end
