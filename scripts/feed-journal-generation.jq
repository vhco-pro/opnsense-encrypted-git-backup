# GitHub deployment IDs order the single-writer journal. The HTTP fixture
# exposes the same numeric IDs. Validate the chain before selecting a head.
sort_by(.id) |
reduce (.[] | select(.payload.phase != "history-checkpoint")) as $row
  ({latest:null,closed:null,recovery:null,retries:[],retirement:null,rejected:[]};
    if $row.payload.phase == "submission-started" then
      if .latest != null and .latest.payload.attempt != .closed.payload.attempt
      then error("prior submission is unresolved")
      elif ($row.payload.predecessor // "") != (.closed.payload.attempt // "")
      then error("broken generation predecessor")
      else .latest = $row | .recovery = null | .retries = [] | .retirement = null end
    elif $row.payload.phase == "recovery-required" then
      if .recovery != null or .retirement != null or .latest.payload.attempt != $row.payload.candidate
         or .latest.payload.recovery != $row.payload.digest or .latest.sha != $row.sha
         or .closed.payload.attempt == $row.payload.candidate
      then error("conflicting recovery decision") else .recovery = $row end
    elif $row.payload.phase == "recovery-started" then
      if .recovery == null or .recovery.payload.candidate != $row.payload.candidate
         or .recovery.payload.digest != $row.payload.digest or .latest.sha != $row.sha
         or ($row.payload.dispatch != "" and (.retries | any(.payload.dispatch == $row.payload.dispatch)))
         or ($row.payload.dispatch == "" and (.retries | length) > 0
             and ((.retries | last | .payload.attempt) as $last | .rejected | index($last) == null))
         or ((.retries | length) == 0 and $row.payload.source != .recovery.payload.source)
      then error("conflicting recovery submission") else .retries += [$row] end
    elif $row.payload.phase == "create-rejected" then
      if $row.sha != .latest.sha or $row.payload.category != "authentication"
         or (.rejected | index($row.payload.attempt) != null)
         or .closed.payload.attempt == .latest.payload.attempt
         or (if .recovery == null then .latest.payload.attempt != $row.payload.attempt
             else (.retries | last | .payload.attempt) != $row.payload.attempt end)
      then error("conflicting create rejection") else .rejected += [$row.payload.attempt] end
    elif $row.payload.phase == "rejection-closure" then
      if .latest == null or .recovery != null or $row.sha != .latest.sha
         or .latest.payload.attempt != $row.payload.attempt
         or (.rejected | index($row.payload.attempt) == null)
      then error("conflicting rejected candidate closure") else .latest = .closed end
    elif $row.payload.phase == "trust-finalization-pending" then
      if .retirement != null or .recovery != null or .latest.payload.attempt != $row.payload.attempt
         or .latest.sha != $row.sha or .latest.payload.digest != $row.payload.digest
         or .closed.payload.attempt == $row.payload.attempt
      then error("conflicting trust finalization") else .retirement = $row end
    elif $row.payload.phase == "verified-closure" then
      if .latest.payload.attempt != $row.payload.attempt
         or .latest.sha != $row.sha or .latest.payload.digest != $row.payload.digest
         or .closed.payload.attempt == $row.payload.attempt
      then error("conflicting generation closure")
      else .closed = $row end
    else error("unknown generation journal phase") end)
