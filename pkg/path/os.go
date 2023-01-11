// Copyright 2020 CUE Authors
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

package path

import "cuelang.org/go/internal/ospath"

// OS must be a valid runtime.GOOS value or "unix".
type OS string

const (
	Unix    OS = "unix"
	Windows OS = "windows"
	Plan9   OS = "plan9"
)

func getOS(o OS) ospath.OS {
	switch o {
	case Windows:
		return ospath.Windows
	case Plan9:
		return ospath.Plan9
	default:
		// This covers all GOOS values other than the above.
		// Invalid values can't get through because the function
		// signature will reject them.
		return ospath.Unix
	}
}
