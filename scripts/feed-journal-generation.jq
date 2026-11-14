# GitHub deployment IDs order the single-writer journal. The HTTP fixture
# exposes the same numeric IDs. Validate the chain before selecting a head.
sort_by(.id) |
reduce (.[] | select(.payload.phase != "history-checkpoint")) as $row
  ({latest:null,closed:null};
    if $row.payload.phase == "submission-started" then
      if .latest != null and .latest.payload.attempt != .closed.payload.attempt
      then error("prior submission is unresolved")
      elif ($row.payload.predecessor // "") != (.closed.payload.attempt // "")
      then error("broken generation predecessor")
      else .latest = $row end
    elif $row.payload.phase == "verified-closure" then
      if .latest.payload.attempt != $row.payload.attempt
         or .latest.sha != $row.sha or .latest.payload.digest != $row.payload.digest
         or .closed.payload.attempt == $row.payload.attempt
      then error("conflicting generation closure")
      else .closed = $row end
    else error("unknown generation journal phase") end)
