// Copyright 2019 CUE Authors
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

package load

import (
	"cuelang.org/go/cue/ast"
	"cuelang.org/go/internal/sourcefs"
)

// A Source represents file contents.
type Source = sourcefs.Source

// FromString creates a Source from the given string.
func FromString(s string) Source {
	return sourcefs.FromString(s)
}

// FromBytes creates a Source from the given bytes. The contents are not
// copied and should not be modified.
func FromBytes(b []byte) Source {
	return sourcefs.FromBytes(b)
}

// FromFile creates a Source from the given *ast.File. The file should not be
// modified. It is assumed the file is error-free.
func FromFile(f *ast.File) Source {
	return sourcefs.FromFile(f)
}
