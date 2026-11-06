# usage: jq -f lessons.jq candidates.json — prints the errors of a reader's answer; [] means valid
def owners: ["project", "user", "roles"];
def kinds: ["decision", "preference", "pitfall", "question", "fact", "playbook"];
def keys_allowed: ["lesson", "owner", "kind", "evidence", "source"];
def str($v): ($v | type) == "string" and ($v | length) > 0;

if type != "array" then ["the answer is not a JSON array"]
else
  [ to_entries[] | .key as $i | .value as $c
    | if ($c | type) != "object" then "\($i): not an object"
      else
        ( if str($c.lesson) | not then "\($i): lesson missing or empty" else empty end ),
        ( if ($c.lesson | type) == "string" and ($c.lesson | length) > 400 then "\($i): lesson over 400 characters" else empty end ),
        ( if owners | any(. == $c.owner) | not then "\($i): owner \($c.owner | tojson) not one of \(owners | join(", "))" else empty end ),
        ( if kinds | any(. == $c.kind) | not then "\($i): kind \($c.kind | tojson) not one of \(kinds | join(", "))" else empty end ),
        ( if str($c.evidence) | not then "\($i): evidence missing or empty" else empty end ),
        ( if ($c.evidence | type) == "string" and ($c.evidence | length) > 300 then "\($i): evidence over 300 characters" else empty end ),
        ( if str($c.source) | not then "\($i): source missing or empty" else empty end ),
        ( ($c | keys) - keys_allowed | .[] | "\($i): unknown key \(.)" )
      end ]
end
