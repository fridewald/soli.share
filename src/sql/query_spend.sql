-- name: GetSpend :one
SELECT * FROM session WHERE id = ? LIMIT 1;

-- name: GetSpends :many
SELECT * FROM session;


-- name: CreateSpend :one
INSERT INTO session (
 id,
 amount_in_cent,
 name
) VALUES (?, ?, ?) RETURNING *;

-- name: NewPledge :exec
INSERT INTO participation (
  id ,
  session_id ,
  amount_in_cent,
  participant_name)
 VALUES (?, ?, ?, ?);


-- name: GetPledges :many
SELECT * FROM participation p  WHERE p.session_id = ?;
