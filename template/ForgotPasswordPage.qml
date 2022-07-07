import QtQml 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.4 as QC1
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.13
import Esri.ArcGISRuntime.Toolkit 100.13


Rectangle {
    id: page
    property Portal appPortal

    signal close()

        Portal {
            id: portal

            credential: Credential {
                oAuthClientInfo: OAuthClientInfo {
                    oAuthMode: Enums.OAuthModeUser
                    clientId: "me3bKdhpRB3XcUZR"
                }
            }

            Component.onCompleted: {
                load();
                fetchLicenseInfo();
                console.log("ForgotPasswordPage Portal onCompleted");
            }

            onLoadStatusChanged: {
                console.log("ForgotPasswordPage Portal onLoadStatusChanged", loadStatus);
                if (loadStatus === Enums.LoadStatusFailedToLoad)
                    retryLoad();
            }

            onCredentialChanged: {
                console.log("ForgotPasswordPage Portal onCredentialChanged", loadStatus);

            }

            onFetchLicenseInfoStatusChanged: {
                console.log("ForgotPasswordPage Portal onFetchLicenseInfoStatusChanged", fetchLicenseInfoStatus);
                if (fetchLicenseInfoStatus == Enums.TaskStatusCompleted || fetchLicenseInfoStatus == Enums.TaskStatusErrored)
                {
                    console.log("ForgotPasswordPage Portal onFetchLicenseInfoStatusChanged: closing page");
                    page.close();
                }
            }

            onFetchLicenseInfoResultChanged: {
                console.log("ForgotPasswordPage Portal onFetchLicenseInfoResultChanged", fetchLicenseInfoResult);
            }
        }

        AuthenticationView {
            id: authView
            anchors.fill: parent
        }
}
