// Copyright 2021 The CUE Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// package github declares the workflows for this project.
package github

import (
	"strings"

	"cuelang.org/go/internal/ci/core"
	"cuelang.org/go/internal/ci/base"
	"cuelang.org/go/internal/ci/gerrithub"

	"github.com/SchemaStore/schemastore/src/schemas/json"
)

// Note: the name of the workflows (and hence the corresponding .yml filenames)
// correspond to the environment variable names for gerritstatusupdater.
// Therefore, this filename must only be change in combination with also
// updating the environment in which gerritstatusupdater is running for this
// repository.
//
// This name is also used by the CI badge in the top-level README.
//
// This name is also used in the evict_caches lookups.
//
// i.e. don't change the names of workflows!
//
// In addition to separately declaring the workflows themselves, we define the
// shape of #workflows here as a cross-check that we don't accidentally change
// the name of workflows without reading this comment.
//
// We explicitly use close() here instead of a definition in order that we can
// cue export the github package as a test.
workflows: close({
	[string]: json.#Workflow

	trybot:             _
	trybot_dispatch:    _
	release:            _
	tip_triggers:       _
	push_tip_to_trybot: _
	evict_caches:       _
})

// _#protectedBranchPatterns is a list of glob patterns to match the protected
// git branches which are continuously used during development on Gerrit.
// This includes the default branch and release branches,
// but excludes any others like feature branches or short-lived branches.
// Note that #testDefaultBranch is excluded as it is GitHub-only.
_#protectedBranchPatterns: [core.defaultBranch, core.releaseBranchPattern]

// _#matchPattern returns a GitHub Actions expression which evaluates whether a
// variable matches a globbing pattern. For literal patterns it uses "==",
// and for suffix patterns it uses "startsWith".
// See https://docs.github.com/en/actions/learn-github-actions/expressions.
_#matchPattern: {
	variable: string
	pattern:  string
	expr:     [
			if strings.HasSuffix(pattern, "*") {
			let prefix = strings.TrimSuffix(pattern, "*")
			"startsWith(\(variable), '\(prefix)')"
		},
		{
			"\(variable) == '\(pattern)'"
		},
	][0]
}

// _#isProtectedBranch is an expression that evaluates to true if the
// job is running as a result of pushing to one of _#protectedBranchPatterns.
// It would be nice to use the "contains" builtin for simplicity,
// but array literals are not yet supported in expressions.
_#isProtectedBranch: "(" + strings.Join([ for branch in _#protectedBranchPatterns {
	(_#matchPattern & {variable: "github.ref", pattern: "refs/heads/\(branch)"}).expr
}], " || ") + ")"

_#isReleaseTag: (_#matchPattern & {variable: "github.ref", pattern: "refs/tags/\(core.releaseTagPattern)"}).expr

_#linuxMachine:   "ubuntu-22.04"
_#macosMachine:   "macos-11"
_#windowsMachine: "windows-2022"

// _#isLatestLinux evaluates to true if the job is running on Linux with the
// latest version of Go. This expression is often used to run certain steps
// just once per CI workflow, to avoid duplicated work.
_#isLatestLinux: "(matrix.go-version == '\(core.latestStableGo)' && matrix.os == '\(_#linuxMachine)')"

_#testStrategy: {
	"fail-fast": false
	matrix: {
		"go-version": ["1.18.x", core.latestStableGo]
		os: [_#linuxMachine, _#macosMachine, _#windowsMachine]
	}
}

// _gerrithub is an instance of ./gerrithub, parameterised by the properties of
// this project
_gerrithub: gerrithub & {
	#repositoryURL:                      core.githubRepositoryURL
	#botGitHubUser:                      "cueckoo"
	#botGitHubUserTokenSecretsKey:       "CUECKOO_GITHUB_PAT"
	#botGitHubUserEmail:                 "cueckoo@gmail.com"
	#botGerritHubUser:                   #botGitHubUser
	#botGerritHubUserPasswordSecretsKey: "CUECKOO_GERRITHUB_PASSWORD"
	#botGerritHubUserEmail:              #botGitHubUserEmail
}

// _base is an instance of ./base, parameterised by the properties of this
// project
//
// TODO: revisit the naming strategy here. _base and base are very similar.
// Perhaps rename the import to something more obviously not intended to be
// used, and then rename the field base?
_base: base & {
	#repositoryURL:                core.githubRepositoryURL
	#defaultBranch:                core.defaultBranch
	#botGitHubUser:                "cueckoo"
	#botGitHubUserTokenSecretsKey: "CUECKOO_GITHUB_PAT"
}
