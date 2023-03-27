// Copyright 2022 The CUE Authors
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

package github

import (
	"list"

	"cuelang.org/go/internal/ci/repo"

	"github.com/SchemaStore/schemastore/src/schemas/json"
)

// The trybot workflow.
workflows: trybot: repo.bashWorkflow & {
	name: repo.trybot.name

	on: {
		push: {
			branches: list.Concat([["trybot/*/*", repo.testDefaultBranch], repo.protectedBranchPatterns]) // do not run PR branches
			"tags-ignore": [repo.releaseTagPattern]
		}
		pull_request: {}
	}

	jobs: {
		test: {
			strategy:  _testStrategy
			"runs-on": "${{ matrix.os }}"

			let goCaches = repo.setupGoActionsCaches & {#protectedBranchExpr: repo.isProtectedBranch, _}

			steps: [
				for v in repo.checkoutCode {v},
				repo.installGo,

				// cachePre must come after installing Node and Go, because the cache locations
				// are established by running each tool.
				for v in goCaches {v},

				// All tests on protected branches should skip the test cache.
				// The canonical way to do this is with -count=1. However, we
				// want the resulting test cache to be valid and current so that
				// subsequent CLs in the trybot repo can leverage the updated
				// cache. Therefore, we instead perform a clean of the testcache.
				json.#step & {
					if:  "github.repository == '\(repo.githubRepositoryPath)' && (\(repo.isProtectedBranch) || github.ref == 'refs/heads/\(repo.testDefaultBranch)')"
					run: "go clean -testcache"
				},

				repo.earlyChecks & {
					// These checks don't vary based on the Go version or OS,
					// so we only need to run them on one of the matrix jobs.
					if: repo.isLatestLinux
				},
				json.#step & {
					if:  "\(repo.isProtectedBranch) || \(repo.isLatestLinux)"
					run: "echo CUE_LONG=true >> $GITHUB_ENV"
				},
				_goGenerate,
				_goTest & {
					if: "\(repo.isProtectedBranch) || !\(repo.isLatestLinux)"
				},
				_goTestRace & {
					if: repo.isLatestLinux
				},
				_goCheck,
				repo.checkGitClean,
				_pullThroughProxy,
			]
		}
	}

	_testStrategy: {
		"fail-fast": false
		matrix: {
			"go-version": ["1.19.x", repo.latestStableGo]
			os: [repo.linuxMachine, repo.macosMachine, repo.windowsMachine]
		}
	}

	_pullThroughProxy: json.#step & {
		name: "Pull this commit through the proxy on \(repo.defaultBranch)"
		run: """
			v=$(git rev-parse HEAD)
			cd $(mktemp -d)
			go mod init test

			# Try up to five times if we get a 410 error, which either the proxy or sumdb
			# can return if they haven't retrieved the requested version yet.
			for i in {1..5}; do
				# GitHub Actions defaults to "set -eo pipefail", so we use an if clause to
				# avoid stopping too early. We also use a "failed" file as "go get" runs
				# in a subshell via the pipe.
				rm -f failed
				if ! GOPROXY=https://proxy.golang.org go get cuelang.org/go@$v; then
					touch failed
				fi |& tee output.txt

				if [[ -f failed ]]; then
					if grep -q '410 Gone' output.txt; then
						echo "got a 410; retrying"
						sleep 1s # do not be too impatient
						continue
					fi
					exit 1 # some other failure; stop
				else
					exit 0 # success; stop
				fi
			done

			echo "giving up after a number of retries"
			exit 1
			"""
		if: "\(repo.isProtectedBranch) && \(repo.isLatestLinux)"
	}

	_goGenerate: json.#step & {
		name: "Generate"
		run:  "go generate ./..."
		// The Go version corresponds to the precise version specified in
		// the matrix. Skip windows for now until we work out why re-gen is flaky
		if: repo.isLatestLinux
	}

	_goTest: json.#step & {
		name: "Test"
		run:  "go test ./..."
	}

	_goCheck: json.#step & {
		// These checks can vary between platforms, as different code can be built
		// based on GOOS and GOARCH build tags.
		// However, CUE does not have any such build tags yet, and we don't use
		// dependencies that vary wildly between platforms.
		// For now, to save CI resources, just run the checks on one matrix job.
		// TODO: consider adding more checks as per https://github.com/golang/go/issues/42119.
		if:   "\(repo.isLatestLinux)"
		name: "Check"
		run:  "go vet ./..."
	}

	_goTestRace: json.#step & {
		name: "Test with -race"
		run:  "go test -race ./..."
	}
}
