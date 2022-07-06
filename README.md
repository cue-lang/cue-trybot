### `cue-trybot`

This is an almost-empty repository with no secrets or privileges that acts as a
shell for running trybot tests started from the
https://review.gerrithub.io/q/project:cue-lang/cue repository (which replicates
to https://github.com/cue-lang/cue).

See the [package
documentation](https://pkg.go.dev/github.com/cue-lang/cuelang.org/internal/functions/gerritstatusupdater)
for the serverless function that listens to webhooks from this repository for
more information.
