# Read-only decision on correlated provider and native verification evidence.
def terminal: .outcome == "success" or .outcome == "failure";
def rejected: .outcome == "rejected" or .outcome == "failure";
def permitted: .authorized == true;
def unused_dispatch:
  .dispatch as $id | ($id | type == "string" and length > 0)
  and (.consumed | type == "array" and index($id) == null);

if .live == "conflict" or (.live == "source" and .outcome == "unknown") then
  "hold"
elif .live == "recovery" then
  if .outcome == "success" and .checks == "pass" then "close"
  elif terminal and .checks == "fail" and permitted and unused_dispatch then "retry-recovery"
  elif .outcome == "unknown" or (terminal and .checks == null) then "validate"
  else "hold" end
elif .live == "candidate" then
  if .outcome == "failure" or (.outcome == "success" and (.checks == "fail" or .recoveryRequired == true)) then
    if permitted then "recover" else "hold" end
  elif .outcome == "success" and .checks == "pass" then "close"
  elif .outcome == "success" or .outcome == "unknown" then "validate"
  else "hold" end
elif .live == "source" and rejected then
  if .closeCandidate == true and .recoveryRequired != true then "close-candidate"
  elif permitted then "retry"
  else "hold" end
else
  "hold"
end
