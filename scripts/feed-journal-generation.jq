# GitHub deployment IDs order the single-writer journal. The HTTP fixture
# exposes the same numeric IDs. Validate the chain before selecting a head.
sort_by(.id) |
reduce (.[] | select(.payload.phase != "history-checkpoint")) as $row
  ({latest:null,closed:null,recovery:null,retries:[]};
    if $row.payload.phase == "submission-started" then
      if .latest != null and .latest.payload.attempt != .closed.payload.attempt
      then error("prior submission is unresolved")
      elif ($row.payload.predecessor // "") != (.closed.payload.attempt // "")
      then error("broken generation predecessor")
      else .latest = $row | .recovery = null | .retries = [] end
    elif $row.payload.phase == "recovery-required" then
      if .recovery != null or .latest.payload.attempt != $row.payload.candidate
         or .latest.payload.recovery != $row.payload.digest or .latest.sha != $row.sha
         or .closed.payload.attempt == $row.payload.candidate
      then error("conflicting recovery decision") else .recovery = $row end
    elif $row.payload.phase == "recovery-started" then
      if .recovery == null or .recovery.payload.candidate != $row.payload.candidate
         or .recovery.payload.digest != $row.payload.digest or .latest.sha != $row.sha
         or (.retries | any(.payload.dispatch == $row.payload.dispatch))
         or ((.retries | length) == 0 and $row.payload.source != .recovery.payload.source)
      then error("conflicting recovery submission") else .retries += [$row] end
    elif $row.payload.phase == "verified-closure" then
      if .latest.payload.attempt != $row.payload.attempt
         or .latest.sha != $row.sha or .latest.payload.digest != $row.payload.digest
         or .closed.payload.attempt == $row.payload.attempt
      then error("conflicting generation closure")
      else .closed = $row end
    else error("unknown generation journal phase") end)
