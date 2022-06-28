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

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Item {
    id: control

    //--------------------------------------------------------------------------

    property var pages: []
    property int count

    property int currentIndex
    readonly property var currentPage: availablePages[currentIndex]
    readonly property int currentPageNumber: availablePages.indexOf(currentPage) + 1

    property var availablePages: []
    readonly property int availableCount: availablePages.length

    readonly property bool canGoto: availableCount > 0
    readonly property bool canGotoPrevious: canGoto && currentIndex > 0
    readonly property bool canGotoNext: canGoto && currentIndex < (availableCount - 1)
    readonly property bool atFirstPage: !canGoto || currentIndex == 0
    readonly property bool atLastPage: !canGoto || currentIndex == (availableCount - 1)

    property bool debug: false

    //--------------------------------------------------------------------------

    signal pageActivated()

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    function addPage(page) {
        if (debug) {
            console.log("addPage:", page.labelText);
        }

        page.relevantChanged.connect(updateAvailablePages);
        page.hiddenChanged.connect(updateAvailablePages);

        pages.push(page);
        count = pages.length;

        updateAvailablePages();

        if (count > 1) {
            page.activePage = false;
        }
    }

    //--------------------------------------------------------------------------

    function gotoPreviousPage() {
        if (!canGoto) {
            return;
        }

        if (currentIndex > 0) {
            currentIndex--;
        }
    }

    //--------------------------------------------------------------------------

    function gotoNextPage() {
        if (!canGoto) {
            return;
        }

        if (currentIndex < (availableCount - 1)) {
            currentIndex++;
        }
    }

    //--------------------------------------------------------------------------

    function gotoPage(page) {
        if (!canGoto) {
            return;
        }

        var index;
        if (typeof page === "number") {
            index = page;
            page = pages[index]
        } else {
            index = pages.indexOf(page);
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "page:", page, "index:", index);
        }

        if (index < 0 || index >= count) {
            console.error(logCategory, arguments.callee.name, "invalid index:", index, "count:", count);
            return;
        }

        if (availablePages.indexOf(page) < 0) {
            console.error(logCategory, arguments.callee.name, "page not avaialble", index, "availableCount:", availableCount);
            return;
        }

        currentIndex = availablePages.indexOf(page);
    }

    //--------------------------------------------------------------------------

    function gotoFirstPage() {
        gotoPage(0);
    }

    //--------------------------------------------------------------------------

    function gotoLastPage() {
        gotoPage(availableCount - 1);
    }

    //--------------------------------------------------------------------------

    function updateAvailablePages() {
        availablePages = pages.filter(page => page.relevant && !page.hidden);

        if (debug) {
            console.log(logCategory,  arguments.callee.name, "length:", availablePages.length);
        }
    }

    //--------------------------------------------------------------------------

    onCurrentPageChanged: {
        if (!canGoto) {
            return;
        }

        pages.forEach(function(page) {
            page.activePage = page === currentPage;
        });

        pageActivated();
    }

    //--------------------------------------------------------------------------
}
