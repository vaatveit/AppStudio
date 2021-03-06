/* Copyright 2020 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

pragma Singleton

import QtQml 2.12

QtObject {
    //--------------------------------------------------------------------------

    enum Status {
        Draft = 0,
        Complete = 1,
        Submitted = 2,
        SubmitError = 3,
        Inbox = 4
    }

    //--------------------------------------------------------------------------

    readonly property string kModeNew: "new"
    readonly property string kModeEdit: "edit"
    readonly property string kModeView: "view"

    //--------------------------------------------------------------------------

    enum ChangeReason {
        Unspecified = 0,
        User = 1,
        Set = 2,
        Calculated = 3,
        Other = 4
    }

    //--------------------------------------------------------------------------
}

