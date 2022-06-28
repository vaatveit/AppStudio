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

import "../../XForms/Singletons"

QtObject {
    //--------------------------------------------------------------------------

    readonly property string kParameterItemId: "itemId"
    readonly property string kParameterPortalUrl: "portalUrl"
    readonly property string kParameterCenter: "center"
    readonly property string kParameterAction: "action"
    readonly property string kParameterFolder: "folder"
    readonly property string kParameterFilter: "filter"
    readonly property string kParameterCallback: "callback"
    readonly property string kParameterUpdate: "update"
    readonly property string kParameterDownload: "download"

    readonly property string kParameterPrefixField: "field:"
    readonly property string kParameterPrefixQuery: "q:"

    //--------------------------------------------------------------------------

    readonly property string kActionCollect: "collect"
    readonly property string kActionEdit: "edit"
    readonly property string kActionView: "view"
    readonly property string kActionCopy: "copy"

    //--------------------------------------------------------------------------

    readonly property string kUserActionCancel: "cancel"
    readonly property string kUserActionDraft: "draft"
    readonly property string kUserActionSubmit: "submit"

    //--------------------------------------------------------------------------

    readonly property string kFolderInbox: "inbox"
    readonly property string kFolderDrafts: "drafts"
    readonly property string kFolderOutbox: "outbox"
    readonly property string kFolderSent: "sent"
    readonly property string kFolderOverview: "overview"

    readonly property color kColorFolderInbox: "#00aeef"
    readonly property color kColorFolderDrafts: "#ff7e00"
    readonly property color kColorFolderOutbox: "#56ad89"
    readonly property color kColorFolderSent: "#818181"
    readonly property color kColorFolderOverview: "#4c4c4c" //"#202020"

    readonly property color kColorCollect: "#3e78b3"

    //--------------------------------------------------------------------------

    readonly property color kColorWarning: "#a80000"
    readonly property color kColorError: "#a80000"

    //--------------------------------------------------------------------------

    function statusColor(status) {
        switch(status) {
        case XForms.Status.Draft:
            return kColorFolderDrafts;

        case XForms.Status.Complete:
            return kColorFolderOutbox;

        case XForms.Status.Submitted:
            return kColorFolderSent;

        case XForms.Status.SubmitError:
            return kColorError;

        case XForms.Status.Inbox:
            return kColorFolderInbox;

        default:
            return kColorFolderOverview;
        }
    }

    //--------------------------------------------------------------------------
}

